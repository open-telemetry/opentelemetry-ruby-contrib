# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Patches for the ActiveSupport::BroadcastLogger class included in Rails 7.1+
        module ActiveSupportBroadcastLogger
          def add(*args)
            emit_one_broadcast(*args) { super }
          end

          def debug(*args)
            emit_one_broadcast(*args) { super }
          end

          def info(*args)
            emit_one_broadcast(*args) { super }
          end

          def warn(*args)
            emit_one_broadcast(*args) { super }
          end

          def error(*args)
            emit_one_broadcast(*args) { super }
          end

          def fatal(*args)
            emit_one_broadcast(*args) { super }
          end

          def unknown(*args)
            emit_one_broadcast(*args) { super }
          end

          private

          # Emit logs from only one of the loggers in the broadcast.
          # Set @skip_otel_emit to `true` to the rest of the loggers before emitting the logs.
          # Set @skip_otel_emit to `false` after the log is emitted.
          def emit_one_broadcast(*args)
            broadcasts[1..-1].each { |broadcasted_logger| broadcasted_logger.instance_variable_set(:@skip_otel_emit, true) }
            yield
            broadcasts.each { |broadcasted_logger| broadcasted_logger.instance_variable_set(:@skip_otel_emit, false) }
          end
        end
      end
    end
  end
end
