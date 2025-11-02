# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../excon/helpers'

module OpenTelemetry
  module Instrumentation
    module Excon
      module Middlewares
        module Stable
          # Excon middleware for instrumentation
          class TracerMiddleware < ::Excon::Middleware::Base
            HTTP_METHODS_TO_UPPERCASE = %w[connect delete get head options patch post put trace].each_with_object({}) do |method, hash|
              uppercase_method = method.upcase
              hash[method] = uppercase_method
              hash[method.to_sym] = uppercase_method
              hash[uppercase_method] = uppercase_method
            end.freeze

            HTTP_METHODS_TO_SPAN_NAMES = HTTP_METHODS_TO_UPPERCASE.values.each_with_object({}) do |uppercase_method, hash|
              hash[uppercase_method] ||= uppercase_method
            end.freeze

            # Constant for the HTTP status range
            HTTP_STATUS_SUCCESS_RANGE = (100..399)

            def request_call(datum)
              return @stack.request_call(datum) if untraced?(datum)

              http_method = HTTP_METHODS_TO_UPPERCASE[datum[:method]]
              attributes = {
                'http.request.method' => http_method,
                'url.scheme' => datum[:scheme],
                'url.path' => datum[:path],
                'url.full' => OpenTelemetry::Common::Utilities.cleanse_url(::Excon::Utils.request_uri(datum)),
                'server.address' => datum[:hostname],
                'server.port' => datum[:port]
              }
              attributes['url.query'] = datum[:query] if datum[:query]
              peer_service = Excon::Instrumentation.instance.config[:peer_service]
              attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = peer_service if peer_service
              attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)
              span_name = OpenTelemetry::Instrumentation::Excon::Helpers.determine_span_name(attributes, http_method)
              span = tracer.start_span(span_name, attributes: attributes, kind: :client)
              ctx = OpenTelemetry::Trace.context_with_span(span)
              datum[:otel_span] = span
              datum[:otel_token] = OpenTelemetry::Context.attach(ctx)
              OpenTelemetry.propagation.inject(datum[:headers])
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
                token = datum.delete(:otel_token)
                OpenTelemetry::Context.detach(token) if token
                return unless span.recording?

                if datum.key?(:response)
                  response = datum[:response]
                  span.set_attribute('http.response.status_code', response[:status])
                  span.status = OpenTelemetry::Trace::Status.error unless HTTP_STATUS_SUCCESS_RANGE.cover?(response[:status].to_i)
                end

                if datum.key?(:error)
                  span.status = OpenTelemetry::Trace::Status.error('Request has failed')
                  span.record_exception(datum[:error])
                end

                span.finish
              end
            rescue StandardError => e
              OpenTelemetry.handle_error(e)
            end

            def tracer
              Excon::Instrumentation.instance.tracer
            end

            def untraced?(datum)
              datum.key?(:otel_span) || Excon::Instrumentation.instance.untraced?(datum[:host])
            end
          end
        end
      end
    end
  end
end
