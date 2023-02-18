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

          def initialize
            @tracer = OpenTelemetry.tracer_provider.tracer('rack', '1.0')
          end

          # Creates a server span for this current request using the incoming parent context
          # and registers them as the {current_span}
          #
          # @param [Rack::Request] The current HTTP request
          # @param [Rack::Response] This is nil in practice
          # @return [void]
          def on_start(request, _)
            extracted_context = extract_remote_context(request)
            span = new_server_span(extracted_context, request)
            request.env[TOKENS_KEY] = register_current_span(span)
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

          def new_server_span(parent_context, request)
            @tracer.start_span(
              "HTTP #{request.request_method}",
              with_parent: parent_context,
              kind: :server,
              attributes: request_span_attributes(request.env)
            )
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
              span.set_attribute('http.status_code', response.status.to_i)
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
            # attributes.merge!(allowed_request_headers(env))
            attributes
          end
        end
      end
    end
  end
end
