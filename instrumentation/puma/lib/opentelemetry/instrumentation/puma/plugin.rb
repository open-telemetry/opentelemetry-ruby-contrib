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
          if ::Puma::Const::PUMA_VERSION < '7'
            register_puma_6_events(launcher)
          else
            register_puma_7_events(launcher)
          end
        end

        private

        def register_puma_6_events(launcher)
          launcher.events.on_stopped { shutdown_providers }
          launcher.events.on_restart { shutdown_providers }
        end

        def register_puma_7_events(launcher)
          launcher.events.after_stopped { shutdown_providers }
          launcher.events.before_restart { shutdown_providers }
        end

        def shutdown_providers
          return if ENV['OTEL_SDK_DISABLED'] == 'true'

          OpenTelemetry.tracer_provider.shutdown
          OpenTelemetry.meter_provider.shutdown if OpenTelemetry.respond_to?(:meter_provider)
          OpenTelemetry.logger_provider.shutdown if OpenTelemetry.respond_to?(:logger_provider)
        end
      end
    end
  end
end
