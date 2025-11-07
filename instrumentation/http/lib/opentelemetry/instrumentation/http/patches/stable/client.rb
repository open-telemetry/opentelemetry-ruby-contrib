# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      module Patches
        # Module using stable HTTP semantic conventions
        module Stable
          # Module to prepend to HTTP::Client for instrumentation
          module Client
            # Constant for the HTTP status range
            HTTP_STATUS_SUCCESS_RANGE = (100..399)

            def perform(req, options)
              span_data = HttpHelper.span_attrs_for(req.verb)

              uri = req.uri
              span_name = create_span_name(span_data, uri.path)

              attributes = {
                'http.request.method' => span_data.normalized_method,
                'url.scheme' => uri.scheme,
                'url.path' => uri.path,
                'url.full' => "#{uri.scheme}://#{uri.host}",
                'server.address' => uri.host,
                'server.port' => uri.port
              }
              attributes['http.request.method_original'] = span_data.original_method if span_data.original_method
              attributes['url.query'] = uri.query unless uri.query.nil?
              attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

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
              span.status = OpenTelemetry::Trace::Status.error unless HTTP_STATUS_SUCCESS_RANGE.cover?(status_code)
            end

            def create_span_name(span_data, request_path)
              default_span_name = span_data.span_name

              if (implementation = config[:span_name_formatter])
                updated_span_name = implementation.call(span_data.normalized_method, request_path)
                updated_span_name.is_a?(String) ? updated_span_name : default_span_name
              else
                default_span_name
              end
            rescue StandardError
              default_span_name
            end

            def tracer
              HTTP::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
