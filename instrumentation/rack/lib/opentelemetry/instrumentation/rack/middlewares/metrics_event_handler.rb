# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../util'

module OpenTelemetry
  module Instrumentation
    module Rack
      module Middlewares
        # OTel Rack Metrics Event Handler
        #
        # @see Rack::Events
        class MetricsEventHandler
          include ::Rack::Events::Abstract

          OTEL_METRICS = 'otel.rack.metrics'

          def on_start(request, _)
            request.env[OTEL_METRICS] = { start_time: monotonic_time_now_nano }
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def on_error(request, _, error)
            request.env[OTEL_METRICS][:error] = error.class.to_s
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def on_finish(request, response)
            record_http_server_request_duration_metric(request, response)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          def meter
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.meter
          end

          def http_server_request_duration_histogram
            @http_server_request_duration_histogram ||= meter.create_histogram(
              'http.server.request.duration',
              unit: 's',
              description: 'Duration of HTTP server requests.'
            )
          end

          def record_http_server_request_duration_metric(request, response)
            metrics_env = request.env[OTEL_METRICS]
            duration = (monotonic_time_now_nano - metrics_env[:start_time]) / Float(10**9)
            attrs = request_metric_attributes(request.env)
            attrs['error.type'] = metrics_env[:error] if metrics_env[:error]
            attrs['http.response.status.code'] = response.status

            http_server_request_duration_histogram.record(duration, attributes: attrs)
          end

          def monotonic_time_now_nano
            Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
          end

          def request_metric_attributes(env)
            {
              'http.method' => env['REQUEST_METHOD'],
              'http.host' => env['HTTP_HOST'] || 'unknown',
              'http.scheme' => env['rack.url_scheme'],
              'http.route' => "#{env['PATH_INFO']}#{('?' + env['QUERY_STRING']) unless env['QUERY_STRING'].empty?}"
            }
          end
        end
      end
    end
  end
end
