# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      module Patches
        # Patch for Telemetry Plugin Handler in V3 SDK
        module Handler
          def call(context)
            span_wrapper(context) { @handler.call(context) }
          end

          private

          def span_wrapper(context, &block)
            service_id = service_id(context)
            client_method = client_method(service_id, context)
            context.tracer.in_span(
              span_name(context, client_method, service_id),
              attributes: attributes(context, client_method, service_id),
              kind: span_kind(client_method, service_id)
            ) do |span|
              if instrumentation_config[:inject_messaging_context] &&
                 %w[SQS SNS].include?(service_id)
                MessagingHelper.inject_context(context, client_method)
              end

              if instrumentation_config[:suppress_internal_instrumentation]
                OpenTelemetry::Common::Utilities.untraced { super }
              else
                yield span
              end
            end
          end

          def instrumentation_config
            AwsSdk::Instrumentation.instance.config
          end

          def service_id(context)
            context.config.api.metadata['serviceId'] ||
              context.config.api.metadata['serviceAbbreviation'] ||
              context.config.api.metadata['serviceFullName']
          end

          def client_method(service_id, context)
            "#{service_id}.#{context.operation.name}".delete(' ')
          end

          def attributes(context, client_method, service_id)
            {
              'aws.region' => context.config.region,
              OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'aws-api',
              OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_id,
              OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => context.operation.name,
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => context.operation_name.to_s,
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => 'Aws::Plugins::Telemetry'
            }.tap do |attrs|
              attrs[SemanticConventions::Trace::DB_SYSTEM] = 'dynamodb' if service_id == 'DynamoDB'
              MessagingHelper.apply_span_attributes(context, attrs, client_method, service_id) if %w[SQS SNS].include?(service_id)
            end
          end

          def span_name(context, client_method, service_id)
            case service_id
            when 'SQS', 'SNS'
              MessagingHelper.span_name(context, client_method)
            else
              client_method
            end
          end

          def span_kind(client_method, service_id)
            case service_id
            when 'SQS', 'SNS'
              MessagingHelper.span_kind(client_method)
            else
              OpenTelemetry::Trace::SpanKind::CLIENT
            end
          end
        end
      end
    end
  end
end
