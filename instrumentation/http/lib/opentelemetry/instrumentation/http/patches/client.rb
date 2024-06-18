# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      module Patches
        # Module to prepend to HTTP::Client for instrumentation
        module Client
          def perform(req, options)
            uri = req.uri
            request_method = req.verb.to_s.upcase
            span_name = create_request_span_name(request_method, uri.path)

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request_method,
              'http.request.method' => request_method,
              OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => uri.scheme,
              OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => uri.path,
              OpenTelemetry::SemanticConventions::Trace::HTTP_URL => "#{uri.scheme}://#{uri.host}",
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => uri.host,
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => uri.port,
              'server.address' => uri.host,
              'server.port' => uri.port,
              'url.full' => OpenTelemetry::Common::Utilities.cleanse_url(uri.to_s),
              'url.scheme' => uri.scheme
            }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span(span_name, attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.headers)
              super.tap do |response|
                annotate_span_with_response!(span, response)
              end
            end
          end

          private

          def config
            OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance.config
          end

          def annotate_span_with_response!(span, response)
            return unless response&.status

            status_code = response.status.to_i
            span.set_attribute('http.response.status_code', status_code)
            span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, status_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).cover?(status_code.to_i)
          end

          def create_request_span_name(request_method, request_path)
            if (implementation = config[:span_name_formatter])
              updated_span_name = implementation.call(request_method, request_path)
              updated_span_name.is_a?(String) ? updated_span_name : "HTTP #{request_method}"
            else
              "HTTP #{request_method}"
            end
          rescue StandardError
            "HTTP #{request_method}"
          end

          def tracer
            HTTP::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
