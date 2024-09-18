# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Generates Spans for all interactions with AwsSdk
      class Handler < Seahorse::Client::Handler
        def call(context)
          return super unless context

          service_id = service_name(context)
          operation = context.operation&.name
          client_method = "#{service_id}.#{operation}"

          tracer.in_span(
            span_name(context, client_method, service_id),
            attributes: attributes(context, client_method, service_id, operation),
            kind: span_kind(client_method, service_id)
          ) do |span|
            if instrumentation_config[:inject_messaging_context] &&
               %w[SQS SNS].include?(service_id)
              MessagingHelper.inject_context(context, client_method)
            end

            if instrumentation_config[:suppress_internal_instrumentation]
              OpenTelemetry::Common::Utilities.untraced { super }
            else
              super
            end.tap do |response|
              span.set_attribute(
                OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE,
                context.http_response.status_code
              )

              if (err = response.error)
                span.record_exception(err)
                span.status = Trace::Status.error(err.to_s)
              end
            end
          end
        end

        private

        def tracer
          AwsSdk::Instrumentation.instance.tracer
        end

        def instrumentation_config
          AwsSdk::Instrumentation.instance.config
        end

        def service_name(context)
          # Support aws-sdk v2.0.x, which 'metadata' has a setter method only
          return context.client.class.to_s.split('::')[1] if ::Seahorse::Model::Api.instance_method(:metadata).parameters.length.positive?

          context.client.class.api.metadata['serviceId'] || context.client.class.to_s.split('::')[1]
        end

        def span_kind(client_method, service_id)
          case service_id
          when 'SQS', 'SNS'
            MessagingHelper.span_kind(client_method)
          else
            OpenTelemetry::Trace::SpanKind::CLIENT
          end
        end

        def span_name(context, client_method, service_id)
          case service_id
          when 'SQS', 'SNS'
            MessagingHelper.legacy_span_name(context, client_method)
          else
            client_method
          end
        end

        def attributes(context, client_method, service_id, operation)
          {
            'aws.region' => context.config.region,
            OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
            OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => operation,
            OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_id
          }.tap do |attrs|
            attrs[SemanticConventions::Trace::DB_SYSTEM] = 'dynamodb' if service_id == 'DynamoDB'
            MessagingHelper.apply_span_attributes(context, attrs, client_method, service_id) if %w[SQS SNS].include?(service_id)
          end
        end
      end

      # A Seahorse::Client::Plugin that enables instrumentation for all AWS services
      class Plugin < Seahorse::Client::Plugin
        def add_handlers(handlers, _config)
          # run before Seahorse::Client::Plugin::ParamValidator (priority 50)
          handlers.add Handler, step: :validate, priority: 49
        end
      end
    end
  end
end
