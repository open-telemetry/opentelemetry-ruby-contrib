# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Excon
      # The Instrumentation class contains logic to detect and install the Excon
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          add_middleware
          patch
        end

        present do
          defined?(::Excon)
        end

        option :peer_service, default: nil, validate: :string

        # untraced_hosts: if a request's address matches any of the `String`
        #   or `Regexp` in this array, the instrumentation will not record a
        #   `kind = :client` representing the request and will not propagate
        #   context in the request.
        option :untraced_hosts, default: [], validate: :array

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
          require_relative 'patches/socket'
        end

        def add_middleware
          ::Excon.defaults[:middlewares] = Middlewares::TracerMiddleware.around_default_stack
        end

        def patch
          ::Excon::Socket.prepend(Patches::Socket)
        end
      end
    end
  end
end
