# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Puma
      # The Instrumentation class contains logic to detect and install the Puma instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_configuration
        end

        present do
          defined?(::Puma)
        end

        private

        def require_dependencies
          require_relative 'plugin'
          require_relative 'patches/configuration'
        end

        def patch_configuration
          ::Puma::Configuration.prepend(Patches::Configuration)
        end
      end
    end
  end
end
