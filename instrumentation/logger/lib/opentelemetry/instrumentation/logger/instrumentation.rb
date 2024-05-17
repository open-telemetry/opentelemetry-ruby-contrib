# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      # The Instrumentation class contains logic to detect and install the Logger instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Logger) && defined?(::OpenTelemetry::SDK::Logs)
        end

        option :name, default: OpenTelemetry::Instrumentation::Logger::NAME, validate: :string
        option :version, default: OpenTelemetry::Instrumentation::Logger::VERSION, validate: :string

        private

        def patch
          ::Logger.prepend(Patches::Logger)
          active_support_patch
        end

        def require_dependencies
          require_relative 'patches/logger'
        end

        def active_support_patch
          return unless defined?(::ActiveSupport::Logger)

          require_relative 'patches/active_support_logger'
          ::ActiveSupport::Logger.singleton_class.prepend(Patches::ActiveSupportLogger)
        end
      end
    end
  end
end
