# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        module Metrics
          def request(req, body = nil, &block)
            return super unless started?
            return super if untraced?

            start_time = (Time.now.to_f * 1000).to_i
            error_occurred = false

            begin
              super
            rescue => e
              error_occurred = true
              raise
            ensure
              duration_ms = (Time.now.to_f * 1000).to_i - start_time
              record_metric(duration_ms, req, error_occurred)
            end
          end

          private

          def record_metric(duration_ms, req, error_occurred)
            instrumentation = ::OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance
            return unless instrumentation

            instrumentation.config[:client_request_duration]&.record(duration_ms)
          rescue => e
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
