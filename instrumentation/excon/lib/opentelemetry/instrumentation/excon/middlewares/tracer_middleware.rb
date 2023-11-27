# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Excon
      module Middlewares
        # Excon middleware for instrumentation
        class TracerMiddleware < ::Excon::Middleware::Base
          HTTP_METHODS_TO_UPPERCASE = %w[connect delete get head options patch post put trace].each_with_object({}) do |method, hash|
            uppercase_method = method.upcase
            hash[method] = uppercase_method
            hash[method.to_sym] = uppercase_method
            hash[uppercase_method] = uppercase_method
          end.freeze

          HTTP_METHODS_TO_SPAN_NAMES = HTTP_METHODS_TO_UPPERCASE.values.each_with_object({}) do |uppercase_method, hash|
            hash[uppercase_method] ||= "HTTP #{uppercase_method}"
          end.freeze

          def request_call(datum)
            begin
              unless datum.key?(:otel_span)
                http_method = HTTP_METHODS_TO_UPPERCASE[datum[:method]]
                attributes = span_creation_attributes(datum, http_method)
                tracer.start_span(
                  HTTP_METHODS_TO_SPAN_NAMES[http_method],
                  attributes: attributes,
                  kind: :client
                ).tap do |span|
                  datum[:otel_span] = span
                  OpenTelemetry::Trace.with_span(span) do
                    OpenTelemetry.propagation.inject(datum[:headers])
                  end
                end
              end
            rescue StandardError => e
              OpenTelemetry.logger.debug(e.message)
            end

            @stack.request_call(datum)
          end

          def response_call(datum)
            @stack.response_call(datum).tap do |d|
              handle_response(d)
            end
          end

          def error_call(datum)
            handle_response(datum)
            @stack.error_call(datum)
          end

          # Returns a copy of the default stack with the trace middleware injected
          def self.around_default_stack
            ::Excon.defaults[:middlewares].dup.tap do |default_stack|
              # If the default stack contains a version of the trace middleware already...
              existing_trace_middleware = default_stack.find { |m| m <= TracerMiddleware }
              default_stack.delete(existing_trace_middleware) if existing_trace_middleware

              # Inject after the ResponseParser middleware
              response_middleware_index = default_stack.index(::Excon::Middleware::ResponseParser).to_i
              default_stack.insert(response_middleware_index + 1, self)
            end
          end

          private

          def handle_response(datum)
            if datum.key?(:otel_span)
              datum[:otel_span].tap do |span|
                return span if span.end_timestamp

                if datum.key?(:response)
                  response = datum[:response]
                  span.set_attribute('http.status_code', response[:status])
                  span.status = OpenTelemetry::Trace::Status.error unless (100..399).cover?(response[:status].to_i)
                end

                span.status = OpenTelemetry::Trace::Status.error("Request has failed: #{datum[:error]}") if datum.key?(:error)

                span.finish
                datum.delete(:otel_span)
              end
            end
          rescue StandardError => e
            OpenTelemetry.logger.debug(e.message)
          end

          def span_creation_attributes(datum, http_method)
            instrumentation_attrs = {
              'http.host' => datum[:host],
              'http.method' => http_method,
              'http.scheme' => datum[:scheme],
              'http.target' => datum[:path]
            }
            config = Excon::Instrumentation.instance.config
            instrumentation_attrs['peer.service'] = config[:peer_service] if config[:peer_service]
            instrumentation_attrs.merge!(
              OpenTelemetry::Common::HTTP::ClientContext.attributes
            )
          end

          def tracer
            Excon::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
