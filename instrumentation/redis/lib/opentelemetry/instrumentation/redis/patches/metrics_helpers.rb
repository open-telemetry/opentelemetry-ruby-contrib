# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        # Common logic for tracking histograms and other metrics instruments
        module MetricsHelpers
          private

          def otel_record_histogram(histogram, attributes)
            t0 = otel_monotonic_now
            yield.tap do |result|
              attributes['error.type'] = result.class.to_s if result.is_a?(StandardError)
            end
          rescue StandardError => e
            attributes['error.type'] = e.class.to_s
            raise
          ensure
            duration = otel_monotonic_now - t0
            histogram.record(duration, attributes: attributes)
          end

          def otel_monotonic_now
            Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
          end
        end
      end
    end
  end
end
