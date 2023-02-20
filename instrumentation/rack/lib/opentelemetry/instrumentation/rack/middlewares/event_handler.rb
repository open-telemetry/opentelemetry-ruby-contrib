# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/status'

module OpenTelemetry
  module Instrumentation
    module Rack
      module Middlewares
        # OTel Rack Event Handler
        #
        # This seeds the root context for this service with the server span as the `current_span`
        # allowing for callers later in the stack to reference it using {OpenTelemetry::Trace.current_span}
        #
        # It also registers the server span in a context dedicated to this instrumentation that users may look up
        # using {OpenTelemetry::Instrumentation::Rack.current_span}, which makes it possible for users to mutate the span,
        # e.g. add events or update the span name like in the {ActionPack} instrumentation.
        #
        # @example Rack App Using BodyProxy
        #   GLOBAL_LOGGER = Logger.new($stderr)
        #   APP_TRACER = OpenTelemetry.tracer_provider.tracer('my-app', '1.0.0')
        #
        #   Rack::Builder.new do
        #     use Rack::Events, [OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler.new]
        #     run lambda { |_arg|
        #       APP_TRACER.in_span('hello-world') do |_span|
        #         body = Rack::BodyProxy.new(['hello world!']) do
        #           rack_span = OpenTelemetry::Instrumentation::Rack.current_span
        #           GLOBAL_LOGGER.info("otel.trace_id=#{rack_span.context.hex_trace_id} otel.span_id=#{rack_span.context.hex_span_id}")
        #         end
        #         [200, { 'Content-Type' => 'text/plain' }, body]
        #       end
        #     }
        #   end
        #
        # @see Rack::Events
        # @see OpenTelemetry::Instrumentation::Rack.current_span
        class EventHandler
          include ::Rack::Events::Abstract

          TOKENS_KEY = 'otel.context.tokens'
          GOOD_HTTP_STATUSES = (100..499).freeze

          def initialize(untraced_endpoints:, untraced_callable:,
                         allowed_request_headers:, allowed_response_headers:,
                         url_quantization:, response_propagators:)
            @tracer = OpenTelemetry.tracer_provider.tracer('rack', '1.0')
            @untraced_endpoints = Array(untraced_endpoints).compact
            @untraced_callable = untraced_callable
            @allowed_request_headers = Array(allowed_request_headers)
              .compact
              .each_with_object({}) do |header, memo|
                key = header.to_s.upcase.gsub(/[-\s]/, '_')
                case key
                when 'CONTENT_TYPE', 'CONTENT_LENGTH'
                  memo[key] = build_attribute_name('http.request.header.', header)
                else
                  memo["HTTP_#{key}"] = build_attribute_name('http.request.header.', header)
                end
              end
            @allowed_response_headers = Array(allowed_response_headers).each_with_object({}) do |header, memo|
              memo[header] = build_attribute_name('http.response.header.', header)
              memo[header.to_s.upcase] = build_attribute_name('http.response.header.', header)
            end
            @url_quantization = url_quantization
            @response_propagators = response_propagators
          end

          # Creates a server span for this current request using the incoming parent context
          # and registers them as the {current_span}
          #
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] This is nil in practice
          # @return [void]
          def on_start(request, _)
            return if untraced_request?(request.env)

            extracted_context = extract_remote_context(request)
            span = new_server_span(extracted_context, request)
            request.env[TOKENS_KEY] = register_current_span(span)
          end

          # Optionally adds debugging response headers injected from {response_propagators}
          #
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] This current HTTP response
          # @return [void]
          def on_commit(request, response)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            begin
              @response_propagators&.each { |propagator| propagator.inject(response.headers) }
            rescue StandardError => e
              OpenTelemetry.handle_error(message: 'Unable to inject response propagation headers', exception: e)
            end
          end

          # Records Unexpected Exceptions on the Rack span and set the Span Status to Error
          #
          # @note does nothing if the span is a non-recording span
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] The current HTTP response
          # @param [Exception] An unxpected error raised by the application
          def on_error(request, _, error)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            span.record_exception(error)
            span.status = OpenTelemetry::Trace::Status.error
          end

          # Finishes the span making it eligible to be exported and cleans up existing contexts
          #
          # @note does nothing if the span is a non-recording span
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] The current HTTP response
          def on_finish(request, response)
            finish_rack_span(response)
            remove_contexts(request)
          end

          private

          EMPTY_HASH = {}.freeze
          def extract_request_headers(env)
            return EMPTY_HASH if @allowed_request_headers.empty?

            @allowed_request_headers.each_with_object({}) do |(key, value), result|
              result[value] = env[key] if env.key?(key)
            end
          end

          def extract_response_attributes(response)
            attributes = { 'http.status_code' => response.status.to_i }
            attributes.merge!(extract_response_headers(response.headers))
            attributes
          end

          def extract_response_headers(headers)
            return EMPTY_HASH if @allowed_response_headers.empty?

            @allowed_response_headers.each_with_object({}) do |(key, value), result|
              if headers.key?(key)
                result[value] = headers[key]
              else
                # do case-insensitive match:
                headers.each do |k, v|
                  if k.upcase == key
                    result[value] = v
                    break
                  end
                end
              end
            end
          end

          def untraced_request?(env)
            return true if @untraced_endpoints.include?(env['PATH_INFO'])
            return true if @untraced_callable&.call(env)

            false
          end

          def new_server_span(parent_context, request)
            @tracer.start_span(
              create_request_span_name(request),
              with_parent: parent_context,
              kind: :server,
              attributes: request_span_attributes(request.env)
            )
          end

          # https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#name
          #
          # recommendation: span.name(s) should be low-cardinality (e.g.,
          # strip off query param value, keep param name)
          #
          # see http://github.com/open-telemetry/opentelemetry-specification/pull/416/files
          def create_request_span_name(request)
            # NOTE: dd-trace-rb has implemented 'quantization' (which lowers url cardinality)
            #       see Datadog::Quantization::HTTP.url

            if (implementation = @url_quantization)
              request_uri_or_path_info = request.env['REQUEST_URI'] || request.path_info
              implementation.call(request_uri_or_path_info, request.env)
            else
              "HTTP #{request.request_method}"
            end
          end

          def extract_remote_context(request)
            OpenTelemetry.propagation.extract(
              request.env,
              getter: OpenTelemetry::Common::Propagation.rack_env_getter
            )
          end

          def register_current_span(span)
            ctx = OpenTelemetry::Trace.context_with_span(span)
            rack_ctx = OpenTelemetry::Instrumentation::Rack.context_with_span(span, parent_context: ctx)
            [OpenTelemetry::Context.attach(ctx), OpenTelemetry::Context.attach(rack_ctx)]
          end

          def finish_rack_span(response)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            if response
              span.status = OpenTelemetry::Trace::Status.error unless GOOD_HTTP_STATUSES.include?(response.status.to_i)
              attributes = extract_response_attributes(response)
              span.add_attributes(attributes)
            end
            span.finish
          end

          def remove_contexts(request)
            request.env[TOKENS_KEY]&.reverse&.each do |token|
              OpenTelemetry::Context.detach(token)
            rescue StandardError => e
              OpenTelemetry.handle_error(message: 'Unable to detach Rack Context', exception: e)
            end
          end

          def request_span_attributes(env)
            attributes = {
              'http.method' => env['REQUEST_METHOD'],
              'http.host' => env['HTTP_HOST'] || 'unknown',
              'http.scheme' => env['rack.url_scheme'],
              'http.target' => env['QUERY_STRING'].empty? ? env['PATH_INFO'] : "#{env['PATH_INFO']}?#{env['QUERY_STRING']}"
            }

            attributes['http.user_agent'] = env['HTTP_USER_AGENT'] if env['HTTP_USER_AGENT']
            attributes.merge!(extract_request_headers(env))
            attributes
          end

          def build_attribute_name(prefix, suffix)
            prefix + suffix.to_s.downcase.gsub(/[-\s]/, '_')
          end
        end
      end
    end
  end
end
