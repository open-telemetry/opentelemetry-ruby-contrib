# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'broadcast_logger_context'

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Patches for the ActiveSupport::BroadcastLogger class included in Rails 7.1+
        module ActiveSupportBroadcastLogger
          def add(...)
            emit_one_broadcast { super }
          end

          def debug(...)
            emit_one_broadcast { super }
          end

          def info(...)
            emit_one_broadcast { super }
          end

          def warn(...)
            emit_one_broadcast { super }
          end

          def error(...)
            emit_one_broadcast { super }
          end

          def fatal(...)
            emit_one_broadcast { super }
          end

          def unknown(...)
            emit_one_broadcast { super }
          end

          private

          # Emit logs from only one of the loggers in the broadcast.
          def emit_one_broadcast
            secondary_broadcasts = broadcasts.drop(1)
            return yield if secondary_broadcasts.empty?

            secondary_broadcasts.each do |logger|
              BroadcastLoggerContext.skip_logger(logger)
            end

            yield
          ensure
            secondary_broadcasts&.each do |logger|
              BroadcastLoggerContext.unskip_logger(logger)
            end
          end
        end
      end
    end
  end
end
