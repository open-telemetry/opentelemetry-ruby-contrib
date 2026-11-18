# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Anthropic
      # The Instrumentation class contains logic to detect and install the Anthropic instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MAX_VERSION = Gem::Version.new('1.78.0') # Anthropic 0.39.0+ has native OpenTelemetry instrumentation

        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Anthropic)
        end

        compatible do
          if gem_version > MAX_VERSION
            OpenTelemetry.logger.info("Anthropic #{gem_version} has native OpenTelemetry support. Skipping community instrumentation.")
            false
          else
            true
          end
        end

        private

        def gem_version
          Gem::Version.new(::Anthropic::VERSION)
        end

        def patch
          ::Anthropic::Internal::Transport::PooledNetRequester.prepend(Patches::PooledNetRequester)
        end

        def require_dependencies
          require_relative 'patches/pooled_net_requester'
        end
      end
    end
  end
end
