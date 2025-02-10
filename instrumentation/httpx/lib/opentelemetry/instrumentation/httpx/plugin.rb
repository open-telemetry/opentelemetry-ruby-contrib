# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      module Plugin
        # Instruments around HTTPX's request/response lifecycle in order to generate
        # an OTEL trace.
        class RequestTracer
          # Constant for the HTTP status range
          HTTP_STATUS_SUCCESS_RANGE = (100..399)

          def initialize(request)
            @request = request

            # the span is initialized when the request is buffered in the parser, which is the closest
            # one gets to actually sending the request.
            request.on(:headers) { call }
          end

          # sets up the span, while preparing the on response callback.
          def call(start_time = Time.now)
            return if @span

            uri = @request.uri
            request_method = @request.verb
            span_name = "HTTP #{request_method}"

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::HTTP_HOST => uri.host,
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request_method,
              OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => uri.scheme,
              OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => uri.path,
              OpenTelemetry::SemanticConventions::Trace::HTTP_URL => "#{uri.scheme}://#{uri.host}",
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => uri.host,
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => uri.port
            }
            config = HTTPX::Instrumentation.instance.config
            attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] if config[:peer_service]
            attributes.merge!(
              OpenTelemetry::Common::HTTP::ClientContext.attributes
            )

            @span = tracer.start_span(span_name, attributes: attributes, kind: :client, start_timestamp: start_time)

            OpenTelemetry::Trace.with_span(@span) do
              OpenTelemetry.propagation.inject(@request.headers)
            end

            @request.once(:response, &method(:finish))
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          # finishes the span to what the +response+ state contains.
          # it also resets internal state to allow this object to be reused.
          def finish(response)
            return unless @span

            if response.is_a?(::HTTPX::ErrorResponse)
              @span.record_exception(response.error)
              @span.status = Trace::Status.error("Unhandled exception of type: #{response.error.class}")
            else
              @span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, response.status)
              @span.status = Trace::Status.error unless HTTP_STATUS_SUCCESS_RANGE.cover?(response.status)
            end

            @span.finish
          ensure
            @span = nil
          end

          def tracer
            HTTPX::Instrumentation.instance.tracer
          end
        end

        # HTTPX::Request overrides
        module RequestMethods
          # intercepts request initialization to inject the tracing logic.
          def initialize(*)
            super

            RequestTracer.new(self)
          end
        end

        # HTTPX::Connection overrides
        module ConnectionMethods
          attr_reader :init_time

          def initialize(*)
            super

            @init_time = Time.now
          end

          # handles the case when the +error+ happened during name resolution, which meanns
          # that the tracing logic hasn't been injected yet; in such cases, the approximate
          # initial resolving time is collected from the connection, and used as span start time,
          # and the tracing object in inserted before the on response callback is called.
          def handle_error(error, request = nil)
            return super unless error.respond_to?(:connection)

            @pending.each do |req|
              next if request and request == req

              RequestTracer.new(req).call(error.connection.init_time)
            end

            RequestTracer.new(request).call(error.connection.init_time) if request

            super
          end
        end
      end
    end
  end
end
