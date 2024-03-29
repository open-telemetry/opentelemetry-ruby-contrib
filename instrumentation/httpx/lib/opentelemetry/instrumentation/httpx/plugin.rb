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
          def initialize(request)
            @request = request
          end

          def call
            @request.on(:response, &method(:finish)) # rubocop:disable Performance/MethodObjectAsBlock

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

            @span = tracer.start_span(span_name, attributes: attributes, kind: :client)
            trace_ctx = OpenTelemetry::Trace.context_with_span(@span)
            @trace_token = OpenTelemetry::Context.attach(trace_ctx)

            OpenTelemetry.propagation.inject(@request.headers)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def finish(response)
            return unless @span

            if response.is_a?(::HTTPX::ErrorResponse)
              @span.record_exception(response.error)
              @span.status = Trace::Status.error("Unhandled exception of type: #{response.error.class}")
            else
              @span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, response.status)
              @span.status = Trace::Status.error unless (100..399).cover?(response.status)
            end

            OpenTelemetry::Context.detach(@trace_token) if @trace_token
            @span.finish
          end

          private

          def tracer
            HTTPX::Instrumentation.instance.tracer
          end
        end

        # HTTPX::Request overrides
        module RequestMethods
          def __otel_enable_trace!
            return if @__otel_enable_trace

            RequestTracer.new(self).call
            @__otel_enable_trace = true
          end
        end

        # HTTPX::Connection overrides
        module ConnectionMethods
          def send(request)
            request.__otel_enable_trace!

            super
          end
        end
      end
    end
  end
end
