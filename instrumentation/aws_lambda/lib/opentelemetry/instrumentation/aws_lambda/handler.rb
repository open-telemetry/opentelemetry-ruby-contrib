# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsLambda
      # Handler class that creates a span around the _HANDLER
      class Handler
        attr_reader :handler_method, :handler_class

        # anytime when update the code in a Lambda function or change the functional configuration,
        # the next invocation results in a cold start; therefore these instance variable will be up-to-date
        def initialize
          @flush_timeout    = ENV.fetch('OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT', '30000').to_i
          @original_handler = ENV['ORIG_HANDLER'] || ENV['_HANDLER'] || ''
          @handler_class    = nil
          @handler_method   = nil
          @handler_file     = nil

          resolve_original_handler
        end

        # We want to capture the error if user's handler is causing issue
        # but our wrapper and handler shouldn't cause any issue
        def call_wrapped(event:, context:)
          parent_context   = extract_parent_context(event)
          span_attributes  = otel_attributes(event, context)

          response = nil
          original_handler_error = nil
          begin
            response = call_original_handler(event: event, context: context)
            span_attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE] = response['statusCode'] if response.instance_of?(Hash) && response['statusCode']
          rescue StandardError => e
            original_handler_error = e
            span_attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE] = '500'
          end

          OpenTelemetry::Context.with_current(parent_context) do
            span = tracer.start_span(
              @original_handler,
              attributes: span_attributes,
              kind: :server # Span kind MUST be `:server` for a HTTP server span
            )
          rescue StandardError => e
            span&.record_exception(e)
            span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
          ensure
            if original_handler_error
              span&.record_exception(original_handler_error)
              span&.status = OpenTelemetry::Trace::Status.error("Original lambda handler exception: #{original_handler_error.class}. Please check if you have correct handler setting or code in lambda function.")
            end
            span&.finish
            OpenTelemetry.tracer_provider.force_flush(timeout: @flush_timeout)
          end

          raise original_handler_error if original_handler_error

          response
        end

        def instrumentation_config
          AwsLambda::Instrumentation.instance.config
        end

        def tracer
          AwsLambda::Instrumentation.instance.tracer
        end

        private

        # we don't expose error if our code cause issue that block user's code
        def resolve_original_handler
          original_handler_parts = @original_handler.split('.')
          if original_handler_parts.size == 2
            @handler_file, @handler_method = original_handler_parts
          elsif original_handler_parts.size == 3
            @handler_file, @handler_class, @handler_method = original_handler_parts
          else
            OpenTelemetry.logger.error("aws-lambda instrumentation: Invalid handler #{original_handler}, must be of form FILENAME.METHOD or FILENAME.CLASS.METHOD.")
          end

          require @handler_file if @handler_file
        end

        def call_original_handler(event:, context:)
          if @handler_class
            Kernel.const_get(@handler_class).send(@handler_method, event: event, context: context)
          else
            __send__(@handler_method, event: event, context: context)
          end
        end

        # Extract parent context from request headers
        # Downcase Traceparent and Tracestate because TraceContext::TextMapPropagator's TRACEPARENT_KEY and TRACESTATE_KEY are all lowercase
        # If any error occur, rescue and give empty context
        def extract_parent_context(event)
          headers = event['headers'] || {}
          headers.transform_keys! do |key|
            %w[Traceparent Tracestate].include?(key) ? key.downcase : key
          end

          OpenTelemetry.propagation.extract(
            headers,
            getter: OpenTelemetry::Context::Propagation.text_map_getter
          )
        rescue StandardError => e
          OpenTelemetry.logger.error("aws-lambda instrumentation exception occur while extracting parent context: #{e.message}")
          OpenTelemetry::Context.empty
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

        # TODO: need to update Semantic Conventions for invocation_id, trigger and resource_id
        def otel_attributes(event, context)
          span_attributes = event['version'] == '2.0' ? v2_proxy_attributes(event) : v1_proxy_attributes(event)
          span_attributes['faas.invocation_id'] = context.aws_request_id
          span_attributes['faas.trigger']       = context.function_name
          span_attributes[OpenTelemetry::SemanticConventions::Trace::AWS_LAMBDA_INVOKED_ARN] = context.invoked_function_arn
          span_attributes['cloud.resource_id'] = "#{context.invoked_function_arn};#{context.aws_request_id};#{context.function_name}"
          span_attributes
        rescue StandardError => e
          OpenTelemetry.logger.error("aws-lambda instrumentation exception occur while preparing span attributes: #{e.message}")
          {}
        end
      end
    end
  end
end
