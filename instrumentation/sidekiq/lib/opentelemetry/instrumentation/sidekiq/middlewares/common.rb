# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        # Common logic for server and client middlewares
        module Common
          private

          def instrumentation
            Sidekiq::Instrumentation.instance
          end

          def instrumentation_config
            Sidekiq::Instrumentation.instance.config
          end

          # Bypasses _all_ enclosed logic unless metrics are enabled
          def with_meter(&block)
            instrumentation.with_meter(&block)
          end

          # time an inner block and yield the duration to the given callback
          def timed(callback)
            return yield unless metrics_enabled?

            t0 = monotonic_now

            yield.tap do
              callback.call(monotonic_now - t0)
            end
          end

          def realtime_now
            Process.clock_gettime(Process::CLOCK_REALTIME)
          end

          def monotonic_now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def tracer
            instrumentation.tracer
          end

          def metrics_enabled?
            instrumentation.metrics_enabled?
          end
        end
      end
    end
  end
end
