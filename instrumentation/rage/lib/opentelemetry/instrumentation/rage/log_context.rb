# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rage
      # The class provides a custom log context to enrich Rage logs with
      # the current OpenTelemetry trace and span IDs.
      class LogContext
        class << self
          def call
            current_span = OpenTelemetry::Trace.current_span
            return unless current_span.recording?

            {
              trace_id: current_span.context.hex_trace_id,
              span_id: current_span.context.hex_span_id
            }
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
            nil
          end
        end
      end
    end
  end
end
