# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'stable/tracer_middleware'

module OpenTelemetry
  module Instrumentation
    module Rack
      module Middlewares
        # Middleware that wraps TracerMiddleware and adds metrics recording
        # This middleware is designed to be used as a replacement for TracerMiddleware
        # It delegates all tracing work to the original TracerMiddleware
        class TracerMiddlewareWithMetrics
          def initialize(app)
            @app = app
            # Create the original tracer middleware wrapping our app
            @tracer_middleware = Stable::TracerMiddleware.new(@app)
          end

          def call(env)
            start_time = current_time_ms

            begin
              @tracer_middleware.call(env)
            ensure
              record_metric(start_time)
            end
          end

          private

          def current_time_ms
            (Time.now.to_f * 1000).to_i
          end

          def record_metric(start_time)
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
