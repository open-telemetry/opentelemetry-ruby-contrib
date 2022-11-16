# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

# require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Instrumentation
    module Hanami
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.0.0.beta4')

        install do |_|
          OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install({})

          # ::Hanami::Web.register Extensions::TracerExtension
        end
        present { defined?(::Hanami) }
        compatible { gem_version >= MINIMUM_VERSION }

        private

        def gem_version
          Gem::Version.new(::Hanami::VERSION)
        end
      end
    end
  end
end
