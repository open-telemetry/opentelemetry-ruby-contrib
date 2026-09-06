# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      # The `OpenTelemetry::Instrumentation::Logger::Instrumentation` class contains logic to detect and install the
      # Ruby Logger library instrumentation.
      #
      # Installation and configuration of this instrumentation is done within the
      # {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry/SDK#configure-instance_method OpenTelemetry::SDK#configure}
      # block, calling {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use use()}
      # or {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use_all use_all()}.
      #
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Logger) && defined?(::OpenTelemetry::SDK::Logs)
        end

        private

        def patch
          ::Logger.prepend(Patches::Logger)
          active_support_broadcast_logger_patch
          active_support_patch
        end

        def require_dependencies
          require_relative 'patches/logger'
        end

        def active_support_patch
          return unless defined?(::ActiveSupport::Logger) && !defined?(::ActiveSupport::BroadcastLogger)

          require_relative 'patches/active_support_logger'
          ::ActiveSupport::Logger.singleton_class.prepend(Patches::ActiveSupportLogger)
        end

        def active_support_broadcast_logger_patch
          return unless defined?(::ActiveSupport::BroadcastLogger)

          require_relative 'patches/active_support_broadcast_logger'
          ::ActiveSupport::BroadcastLogger.prepend(Patches::ActiveSupportBroadcastLogger)
        end
      end
    end
  end
end
