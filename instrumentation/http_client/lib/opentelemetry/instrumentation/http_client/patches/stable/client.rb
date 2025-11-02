# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        module Stable
          # Module to prepend to HTTPClient for instrumentation
          module Client
            # Constant for the HTTP status range
            HTTP_STATUS_SUCCESS_RANGE = (100..399)

            private

            def do_get_block(req, proxy, conn, &)
              uri = req.header.request_uri
              url = "#{uri.scheme}://#{uri.host}"
              request_method = req.header.request_method

              attributes = {
                'http.request.method' => request_method,
                'url.scheme' => uri.scheme,
                'url.path' => uri.path,
                'url.full' => url,
                'server.address' => uri.host,
                'server.port' => uri.port
              }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

              attributes['url.query'] = uri.query unless uri.query.nil?

              tracer.in_span(determine_span_name(attributes, request_method), attributes: attributes, kind: :client) do |span|
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

              span.set_attribute('http.response.status_code', status_code)
              span.status = OpenTelemetry::Trace::Status.error unless HTTP_STATUS_SUCCESS_RANGE.cover?(status_code)
            end

            def tracer
              HttpClient::Instrumentation.instance.tracer
            end

            def determine_span_name(attributes, http_method)
              template = attributes['url.template']
              template ? "#{http_method} #{template}" : http_method
            end
          end
        end
      end
    end
  end
end
