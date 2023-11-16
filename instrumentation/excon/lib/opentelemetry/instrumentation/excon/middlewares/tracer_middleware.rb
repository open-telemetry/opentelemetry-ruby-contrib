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
            if skip_trace?(datum)
              return OpenTelemetry::Common::Utilities.untraced do
                @stack.request_call(datum)
              end
            end

            http_method = HTTP_METHODS_TO_UPPERCASE[datum[:method]]

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => http_method,
              OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => datum[:scheme],
              OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => datum[:path],
              OpenTelemetry::SemanticConventions::Trace::HTTP_HOST => datum[:host],
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => datum[:hostname],
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => datum[:port]
            }

            peer_service = Excon::Instrumentation.instance.config[:peer_service]
            attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = peer_service if peer_service
            attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            datum[:otel_span] = tracer.start_span(HTTP_METHODS_TO_SPAN_NAMES[http_method], attributes: attributes, kind: :client)

            OpenTelemetry::Trace.with_span(datum[:otel_span]) do
              OpenTelemetry.propagation.inject(datum[:headers])
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
            datum.delete(:otel_span)&.tap do |span|
              return span unless span.recording?

              if datum.key?(:response)
                response = datum[:response]
                span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, response[:status])
                span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response[:status].to_i)
              end

              span.status = OpenTelemetry::Trace::Status.error("Request has failed: #{datum[:error]}") if datum.key?(:error)

              span.finish
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(e)
          end

          def tracer
            Excon::Instrumentation.instance.tracer
          end

          def skip_trace?(datum)
            datum.key?(:otel_span) || Excon::Instrumentation.instance.config[:untraced_hosts].any? do |host|
              host.is_a?(Regexp) ? host.match?(datum[:host]) : host == datum[:host]
            end
          end
        end
      end
    end
  end
end
