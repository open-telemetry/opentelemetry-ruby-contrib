# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'broadcast_logger_context'

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Patches for the ActiveSupport::Logger class included in Rails
        module ActiveSupportLogger
          # The ActiveSupport::Logger.broadcast method emits identical logs to
          # multiple destinations. This prevents the broadcasted destinations from
          # generating OpenTelemetry log record objects only during broadcast emission.
          # Available in Rails 7.0 and below
          def broadcast(logger)
            broadcast_module = super
            broadcast_module.prepend(Module.new do
              define_method(:add) do |*args, &block|
                BroadcastLoggerContext.skip_logger(logger)
                begin
                  super(*args, &block)
                ensure
                  BroadcastLoggerContext.unskip_logger(logger)
                end
              end
            end)
            broadcast_module
          end
        end
      end
    end
  end
end
