# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'puma/plugin'

module OpenTelemetry
  module Instrumentation
    module Puma
      # The Puma plugin for OpenTelemetry
      class Plugin < ::Puma::Plugin
        ::Puma::Plugins.register('opentelemetry', self)

        def start(launcher)
          launcher.events.on_stopped do
            shutdown_providers
          end

          launcher.events.on_restart do
            shutdown_providers
          end
        end

        private

        def shutdown_providers
          OpenTelemetry.tracer_provider.shutdown
          OpenTelemetry.meter_provider.shutdown if OpenTelemetry.respond_to?(:meter_provider)
          OpenTelemetry.logger_provider.shutdown if OpenTelemetry.respond_to?(:logger_provider)
        end
      end
    end
  end
end
