# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../concerns/untraced_hosts'

module OpenTelemetry
  module Instrumentation
    module Excon
      # The Instrumentation class contains logic to detect and install the Excon
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        include OpenTelemetry::Instrumentation::Concerns::UntracedHosts

        install do |_config|
          require_dependencies
          add_middleware
          patch
        end

        present do
          defined?(::Excon)
        end

        option :peer_service, default: nil, validate: :string

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
