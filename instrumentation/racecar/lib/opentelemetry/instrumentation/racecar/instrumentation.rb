# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Racecar
      # The Instrumentation class contains logic to detect and install the Racecar instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.7')

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        install do |_config|
          require_patches
          patch
        end

        present do
          defined?(::Racecar)
        end

        private

        def require_patches
          require_relative 'patches/runner'
          require_relative 'patches/consumer'
        end

        def patch
          ::Racecar::Runner.prepend(Patches::Runner)
          ::Racecar::Consumer.prepend(Patches::Consumer)
        end

        def gem_version
          require 'racecar/version'
          Gem::Version.new(::Racecar::VERSION)
        end
      end
    end
  end
end
