# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        # Module to prepend to HTTPClient for instrumentation
        module Client
          private

          def do_get_block(req, proxy, conn, &block)
            uri = req.header.request_uri
            url = "#{uri.scheme}://#{uri.host}"
            request_method = req.header.request_method

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request_method,
              OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => uri.scheme,
              OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => uri.path,
              OpenTelemetry::SemanticConventions::Trace::HTTP_URL => url,
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => uri.host,
              OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => uri.port
            }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span("HTTP #{request_method}", attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.header)
              super.tap do
                response = conn.pop
                annotate_span_with_response!(span, response)
                conn.push response
              end
            end
          end

          def annotate_span_with_response!(span, response)
            return unless response&.status_code

            status_code = response.status_code.to_i

            span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, status_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).cover?(status_code.to_i)
          end

          def tracer
            HttpClient::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
