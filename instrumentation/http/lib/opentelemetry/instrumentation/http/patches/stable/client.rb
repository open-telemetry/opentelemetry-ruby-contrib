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
            # Constant for the HTTP status range. Deprecated. Use HttpHelper::HTTP_STATUS_SUCCESS_RANGE
            HTTP_STATUS_SUCCESS_RANGE = (100..399)

            def perform(req, options)
              span_data = HttpHelper.span_attrs_for_stable(req.verb)

              uri = req.uri
              span_name = create_span_name(span_data, uri.path)

              attributes = { 'url.scheme' => uri.scheme,
                             'url.path' => uri.path,
                             'url.full' => "#{uri.scheme}://#{uri.host}",
                             'server.address' => uri.host,
                             'server.port' => uri.port }
              attributes['url.query'] = uri.query unless uri.query.nil?
              attributes.merge!(span_data.attributes)

              tracer.in_span(span_name, attributes: attributes, kind: :client) do |span|
                start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
                response = nil
                error_type = nil

                begin
                  OpenTelemetry.propagation.inject(req.headers)
                  response = super
                  annotate_span_with_response!(span, response)
                  response
                rescue StandardError => e
                  error_type = e.class.name
                  raise
                ensure
                  record_duration_metric(start_time, attributes['http.request.method'], uri.host, uri.port, response, error_type)
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
              span.status = OpenTelemetry::Trace::Status.error unless HttpHelper::HTTP_STATUS_SUCCESS_RANGE.cover?(status_code)
            end

            def record_duration_metric(start_time, method, address, port, response, error_type) # rubocop:disable Metrics/ParameterLists
              duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
              histogram = client_request_duration_histogram
              return unless histogram

              histogram.record(duration, attributes: HttpHelper.metric_attrs(method, address, port, response, error_type))
            end

            def create_span_name(span_data, request_path)
              default_span_name = span_data.span_name

              if (implementation = config[:span_name_formatter])
                # Extract the HTTP method from attributes
                http_method = span_data.attributes['http.request.method']
                updated_span_name = implementation.call(http_method, request_path)
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

            def client_request_duration_histogram
              HTTP::Instrumentation.instance.client_request_duration_histogram
            end
          end
        end
      end
    end
  end
end
