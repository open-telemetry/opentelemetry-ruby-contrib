# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentation-rdkafka'

module OpenTelemetry
  module Instrumentation
    module Racecar
      # The Instrumentation class contains logic to detect and install the Racecar instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.0')

        compatible do
          Gem.loaded_specs['racecar'].version >= MINIMUM_VERSION
        end

        install do |_config|
          OpenTelemetry::Instrumentation::Rdkafka::Instrumentation.instance.install({})
          require_patches
          patch
        end

        present do
          defined?(::Racecar)
        end

        private

        def require_patches
          require_relative 'patches/runner'
        end

        def patch
          ::Racecar::Runner.prepend(Patches::Runner)
        end
      end
    end
  end
end
