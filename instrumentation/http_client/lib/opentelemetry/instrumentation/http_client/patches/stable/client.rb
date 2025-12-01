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
              span_data = HttpHelper.span_attrs_for(request_method)

              attributes = {
                'http.request.method' => span_data.normalized_method,
                'url.scheme' => uri.scheme,
                'url.path' => uri.path,
                'url.full' => url,
                'server.address' => uri.host,
                'server.port' => uri.port
              }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

              attributes['http.request.method_original'] = span_data.original_method if span_data.original_method
              attributes['url.query'] = uri.query unless uri.query.nil?

              tracer.in_span(span_data.span_name, attributes: attributes, kind: :client) do |span|
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
          end
        end
      end
    end
  end
end
