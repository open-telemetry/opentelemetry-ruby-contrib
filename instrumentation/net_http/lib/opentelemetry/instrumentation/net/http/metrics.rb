# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        # Metrics module for patching the instrumentation
        module Metrics
          def request(req, body = nil, &)
            with_metric_timing { super }
          end

          private

          def connect
            with_metric_timing { super }
          end

          def with_metric_timing
            return yield unless started?
            return yield if untraced?

            start_time = current_time_ms

            yield
          ensure
            record_metric(current_time_ms - start_time) if start_time
          end

          def current_time_ms
            (Time.now.to_f * 1000).to_i
          end

          def record_metric(duration_ms)
            instrumentation = ::OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance
            return unless instrumentation

            instrumentation.config[:client_request_duration]&.record(duration_ms)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def untraced?
            OpenTelemetry::Common::Utilities.untraced?
          end
        end
      end
    end
  end
end
