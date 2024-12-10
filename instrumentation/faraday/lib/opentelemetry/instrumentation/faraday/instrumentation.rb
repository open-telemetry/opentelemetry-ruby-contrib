# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      # The Instrumentation class contains logic to detect and install the Faraday
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('1.0')

        install do |_config|
          require_dependencies
          register_tracer_middleware
          use_middleware_by_default
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        present do
          defined?(::Faraday)
        end

        option :span_kind, default: :client, validate: %i[client internal]
        option :peer_service, default: nil, validate: :string

        private

        def gem_version
          Gem::Version.new(::Faraday::VERSION)
        end

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
          require_relative 'patches/connection'
        end

        def register_tracer_middleware
          ::Faraday::Middleware.register_middleware(
            open_telemetry: Middlewares::TracerMiddleware
          )
        end

        def use_middleware_by_default
          ::Faraday::Connection.prepend(Patches::Connection)
        end
      end
    end
  end
end
