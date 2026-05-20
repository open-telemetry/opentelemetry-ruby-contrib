# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Tracks broadcast logger emission state for the current fiber.
        module BroadcastLoggerContext
          SKIP_LOGGERS_KEY = :_otel_broadcast_skip_loggers
          private_constant :SKIP_LOGGERS_KEY

          class << self
            def skipped_logger?(logger)
              skip_loggers&.key?(logger) || false
            end

            def skip_logger(logger)
              skip_loggers_for_write[logger] += 1
            end

            def unskip_logger(logger)
              skip_loggers = self.skip_loggers
              return unless skip_loggers&.key?(logger)

              skip_loggers[logger] -= 1
              skip_loggers.delete(logger) if skip_loggers[logger].zero?
              Fiber[SKIP_LOGGERS_KEY] = nil if skip_loggers.empty?
            end

            private

            def skip_loggers
              Fiber[SKIP_LOGGERS_KEY]
            end

            def skip_loggers_for_write
              skip_loggers || Hash.new(0).compare_by_identity.tap do |skip_loggers|
                Fiber[SKIP_LOGGERS_KEY] = skip_loggers
              end
            end
          end
        end
      end
    end
  end
end
