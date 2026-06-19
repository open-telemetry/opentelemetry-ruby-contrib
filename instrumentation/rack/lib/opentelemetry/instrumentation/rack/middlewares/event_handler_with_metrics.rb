# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rack
      module Middlewares
        # EventHandler that only records metrics
        # This handler is designed to be used alongside the original EventHandler
        # in the Rack::Events middleware stack
        class EventHandlerWithMetrics
          include ::Rack::Events::Abstract

          OTEL_SERVER_START_TIME = 'otel.rack.server.start_time'

          def on_start(request, _)
            request.env[OTEL_SERVER_START_TIME] = current_time_ms
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def on_commit(_request, _response)
            # No-op: metrics are recorded in on_finish
          end

          def on_error(_request, _response, _error)
            # No-op: metrics are recorded in on_finish
          end

          def on_finish(request, _response)
            record_metric(request)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          def current_time_ms
            (Time.now.to_f * 1000).to_i
          end

          def record_metric(request)
            start_time = request.env[OTEL_SERVER_START_TIME]
            return unless start_time

            duration_ms = current_time_ms - start_time
            config[:server_request_duration]&.record(duration_ms)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def config
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
