# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Patches for the ActiveSupport::Logger class included in Rails
        module ActiveSupportLogger
          # The ActiveSupport::Logger.broadcast method emits identical logs to
          # multiple destinations. This instance variable will prevent the broadcasted
          # destinations from generating OpenTelemetry log record objects.
          # Available in Rails 7.0 and below
          def broadcast(logger)
            logger.instance_variable_set(:@skip_otel_emit, true)
            super
          end
        end
      end
    end
  end
end
