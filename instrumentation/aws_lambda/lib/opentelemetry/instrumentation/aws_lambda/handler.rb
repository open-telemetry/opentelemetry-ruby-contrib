# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsLambda
      # Handler class that create span around the _HANDLER
      class Handler
        attr_reader :handler_method, :handler_class

        def initialize
          @flush_timeout = ENV.fetch('OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT', '30000').to_i
        end

        # Extract context from request headers
        def call_wrapped(event:, context:)
          parent_context   = extract_parent_context(event)
          span_attributes  = event['version'] == '2.0' ? v2_proxy_attributes(event) : v1_proxy_attributes(event)
          original_handler = resolve_original_handler
          response         = call_original_handler(event: event, context: context)

          span_attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE] = response['statusCode'] if response.instance_of?(Hash) && response['statusCode']
          span_attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_ID]       = context.invoked_function_arn
          span_attributes[OpenTelemetry::SemanticConventions::Trace::FAAS_EXECUTION]   = context.aws_request_id

          OpenTelemetry::Context.with_current(parent_context) do
            span = tracer.start_span(
              original_handler,
              attributes: span_attributes,
              kind: :server # Span kind MUST be `:server` for a HTTP server span
            )
          rescue Exception => e # rubocop:disable Lint/RescueException
            span&.record_exception(e)
            span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
            raise e
          ensure
            span&.finish
            OpenTelemetry.tracer_provider.force_flush(timeout: @flush_timeout)
          end
        end

        def resolve_original_handler
          original_handler = ENV['ORIG_HANDLER'] || ENV['_HANDLER'] || ''
          original_handler_parts = original_handler.split('.')
          if original_handler_parts.size == 2
            _, @handler_method = original_handler_parts
          elsif original_handler_parts.size == 3
            _, @handler_class, @handler_method = original_handler_parts
          else
            OpenTelemetry.logger.warn("aws-lambda instrumentation: Invalid handler #{original_handler}, must be of form FILENAME.METHOD or FILENAME.CLASS.METHOD.")
          end
          original_handler
        end

        def call_original_handler(event:, context:)
          if @handler_class
            Kernel.const_get(@handler_class).send(@handler_method, event: event, context: context)
          else
            __send__(@handler_method, event: event, context: context)
          end
        end

        def instrumentation_config
          AwsLambda::Instrumentation.instance.config
        end

        def tracer
          AwsLambda::Instrumentation.instance.tracer
        end

        private

        # Downcase Traceparent and Tracestate because TraceContext::TextMapPropagator's TRACEPARENT_KEY and TRACESTATE_KEY are all lowercase
        def extract_parent_context(event)
          headers = event['headers'] || {}
          headers.transform_keys! do |key|
            %w[Traceparent Tracestate].include?(key) ? key.downcase : key
          end

          OpenTelemetry.propagation.extract(
            headers,
            getter: OpenTelemetry::Context::Propagation.text_map_getter
          )
        end

        def v1_proxy_attributes(event)
          attributes = {
            OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => event['httpMethod'],
            OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE => event['resource'],
            OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => event['resource']
          }
          attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] += "?#{event['queryStringParameters']}" if event['queryStringParameters']

          headers = event['headers']
          if headers
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_USER_AGENT] = headers['User-Agent']
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME]     = headers['X-Forwarded-Proto']
            attributes[OpenTelemetry::SemanticConventions::Trace::NET_HOST_NAME]   = headers['Host']
          end

          attributes
        end

        def v2_proxy_attributes(event)
          request_context = event['requestContext']
          if request_context
            attributes = {
              OpenTelemetry::SemanticConventions::Trace::NET_HOST_NAME => request_context['domainName'],
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request_context['http']['method'],
              OpenTelemetry::SemanticConventions::Trace::HTTP_USER_AGENT => request_context['http']['userAgent'],
              OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE => request_context['http']['path'],
              OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => request_context['http']['path']
            }
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] += "?#{event['rawQueryString']}" if event['rawQueryString']
          else
            attributes = {}
          end

          attributes
        end
      end
    end
  end
end
