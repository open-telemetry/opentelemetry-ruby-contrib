# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../util'
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
          GOOD_HTTP_STATUSES = (100..499)

          # Creates a server span for this current request using the incoming parent context
          # and registers them as the {current_span}
          #
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] This is nil in practice
          # @return [void]
          def on_start(request, _)
            return if untraced_request?(request.env)

            parent_context = extract_remote_context(request)
            links = nil

            fn = propagate_with_link
            if fn&.call(request.env)
              links = prepare_span_links(parent_context)
              parent_context = OpenTelemetry::Context.empty
            end

            span = create_span(parent_context, request, links)
            request.env[TOKENS_KEY] = register_current_span(span)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Optionally adds debugging response headers injected from {response_propagators}
          #
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] This current HTTP response
          # @return [void]
          def on_commit(request, response)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            response_propagators&.each do |propagator|
              propagator.inject(response.headers)
            rescue StandardError => e
              OpenTelemetry.handle_error(message: 'Unable to inject response propagation headers', exception: e)
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
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
            span.status = OpenTelemetry::Trace::Status.error(error.class.name)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Finishes the span making it eligible to be exported and cleans up existing contexts
          #
          # @note does nothing if the span is a non-recording span
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] The current HTTP response
          def on_finish(request, response)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            add_response_attributes(span, response) if response
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          ensure
            detach_contexts(request)
          end

          private

          EMPTY_HASH = {}.freeze
          def extract_request_headers(env)
            return EMPTY_HASH if allowed_request_headers.empty?

            allowed_request_headers.each_with_object({}) do |(key, value), result|
              result[value] = env[key] if env.key?(key)
            end
          end

          def extract_response_attributes(response)
            attributes = { 'http.status_code' => response.status.to_i }
            attributes.merge!(extract_response_headers(response.headers))
            attributes
          end

          def extract_response_headers(headers)
            return EMPTY_HASH if allowed_response_headers.empty?

            allowed_response_headers.each_with_object({}) do |(key, value), result|
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
            return true if untraced_endpoints.include?(env['PATH_INFO'])
            return true if untraced_requests&.call(env)

            false
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

            if (implementation = url_quantization)
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

          def detach_contexts(request)
            request.env[TOKENS_KEY]&.reverse_each do |token|
              OpenTelemetry::Context.detach(token)
              OpenTelemetry::Trace.current_span.finish
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def add_response_attributes(span, response)
            span.status = OpenTelemetry::Trace::Status.error unless GOOD_HTTP_STATUSES.include?(response.status.to_i)
            attributes = extract_response_attributes(response)
            span.add_attributes(attributes)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def record_frontend_span?
            config[:record_frontend_span] == true
          end

          def untraced_endpoints
            config[:untraced_endpoints]
          end

          def untraced_requests
            config[:untraced_requests]
          end

          def url_quantization
            config[:url_quantization]
          end

          def propagate_with_link
            config[:propagate_with_link]
          end

          def response_propagators
            config[:response_propagators]
          end

          def allowed_request_headers
            config[:allowed_rack_request_headers]
          end

          def allowed_response_headers
            config[:allowed_rack_response_headers]
          end

          def tracer
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.tracer
          end

          def config
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.config
          end

          def register_current_span(span)
            ctx = OpenTelemetry::Trace.context_with_span(span)
            rack_ctx = OpenTelemetry::Instrumentation::Rack.context_with_span(span, parent_context: ctx)

            contexts = [ctx, rack_ctx]
            contexts.compact!
            contexts.map { |context| OpenTelemetry::Context.attach(context) }
          end

          def create_span(parent_context, request, links)
            span = tracer.start_span(
              create_request_span_name(request),
              with_parent: parent_context,
              kind: :server,
              attributes: request_span_attributes(request.env),
              links: links
            )
            request_start_time = OpenTelemetry::Instrumentation::Rack::Util::QueueTime.get_request_start(request.env)
            span.add_event('http.proxy.request.started', timestamp: request_start_time) unless request_start_time.nil?
            span
          end

          def prepare_span_links(ctx)
            span_context = OpenTelemetry::Trace.current_span(ctx).context
            span_context.valid? ? [OpenTelemetry::Trace::Link.new(span_context)] : []
          end
        end
      end
    end
  end
end
