# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Dalli
      # The Instrumentation class contains logic to detect and install the Dalli
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          add_patches
        end

        present do
          defined?(::Dalli)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit obfuscate include]

        private

        def require_dependencies
          require_relative 'utils'
          require_relative 'patches/server'
        end

        def add_patches
          if dalli_has_native_otel_support?
            OpenTelemetry.logger.info("Dalli #{::Dalli::VERSION} has native OpenTelemetry support. Skipping community instrumentation")

            return
          end

          if Gem::Version.new(::Dalli::VERSION) < Gem::Version.new('3.0.0')
            ::Dalli::Server.prepend(Patches::Server)
          else
            ::Dalli::Protocol::Binary.prepend(Patches::Server) if defined?(::Dalli::Protocol::Binary)
            ::Dalli::Protocol::Meta.prepend(Patches::Server) if defined?(::Dalli::Protocol::Meta)
          end
        end

        def dalli_has_native_otel_support?
          # Dalli 4.2.0+ has native OpenTelemetry instrumentation
          Gem::Version.new(::Dalli::VERSION) >= Gem::Version.new('4.2.0')
        end
      end
    end
  end
end
