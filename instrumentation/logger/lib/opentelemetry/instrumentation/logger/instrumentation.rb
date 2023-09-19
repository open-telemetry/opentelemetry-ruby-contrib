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
          defined?(Logger)
        end

        # option :name, default: 'default', validate: :validation

        private

        def patch
          ::Logger.prepend(Patches::Logger)
        end

        def require_dependencies
          require_relative 'patches/logger'
        end
      end
    end
  end
end
