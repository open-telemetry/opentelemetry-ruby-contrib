# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../http_helper'

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        module Old
          # Module to prepend to HTTPClient for instrumentation
          module Client
            # Constant for the HTTP status range
            HTTP_STATUS_SUCCESS_RANGE = (100..399)

            private

            def do_get_block(req, proxy, conn, &)
              uri = req.header.request_uri
              url = "#{uri.scheme}://#{uri.host}"
              request_method = req.header.request_method
              normalized_method, _original_method = HttpHelper.normalize_method(request_method)

              span_name = HttpHelper.span_name_for_old(normalized_method)

              attributes = {
                'http.method' => normalized_method,
                'http.scheme' => uri.scheme,
                'http.target' => uri.path,
                'http.url' => url,
                'net.peer.name' => uri.host,
                'net.peer.port' => uri.port
              }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

              tracer.in_span(span_name, attributes: attributes, kind: :client) do |span|
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

              span.set_attribute('http.status_code', status_code)
              span.status = OpenTelemetry::Trace::Status.error unless HTTP_STATUS_SUCCESS_RANGE.cover?(status_code)
            end

            def tracer
              HttpClient::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
