# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveStorage
      # The {OpenTelemetry::Instrumentation::ActiveStorage::Instrumentation} class contains logic to detect and install the ActiveStorage instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('6.1.0')

        install do |_config|
          require_dependencies
        end

        present do
          defined?(::ActiveStorage)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          ::ActiveStorage.version
        end

        def _config
          ActiveStorage::Instrumentation.instance.config
        end

        def require_dependencies
          require_relative 'railtie'
        end
      end
    end
  end
end
