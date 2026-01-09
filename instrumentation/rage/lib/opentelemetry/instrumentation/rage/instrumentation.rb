# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rage
      # The Instrumentation class contains logic to detect and install the Rage instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          unless OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.installed?
            ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] ||= 'http'
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install({ use_rack_events: false })
          end

          require_dependencies
          install_instrumentation
        end

        present do
          defined?(::Rage)
        end

        compatible do
          is_compatible = gem_version >= Gem::Version.new('1.20.0') && gem_version < Gem::Version.new('2')
          OpenTelemetry.logger.warn("Rage version #{::Rage::VERSION} is not supported by the OpenTelemetry Rage instrumentation. Supported versions are >= 1.20.0 and < 2.0.0.") unless is_compatible

          is_compatible
        end

        private

        def gem_version
          Gem::Version.new(::Rage::VERSION)
        end

        def require_dependencies
          require_relative 'log_context'

          require_relative 'handlers/cable'
          require_relative 'handlers/deferred'
          require_relative 'handlers/events'
          require_relative 'handlers/fiber'
          require_relative 'handlers/request'
        end

        def install_instrumentation
          ::Rage.configure do
            # install Rack middleware that creates spans for incoming requests
            config.middleware.insert_after(0, *OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args)

            # install telemetry handler to update request span name and attributes
            config.telemetry.use Handlers::Request

            # install telemetry handler to propagate context to application-level fibers
            config.telemetry.use Handlers::Fiber.new

            # install telemetry handlers for Rage components
            config.telemetry.use Handlers::Cable
            config.telemetry.use Handlers::Deferred
            config.telemetry.use Handlers::Events

            # install log context to add tracing info to logs
            config.log_context << LogContext
          end
        end
      end
    end
  end
end
