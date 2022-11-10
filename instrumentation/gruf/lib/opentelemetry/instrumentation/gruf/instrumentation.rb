# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Gruf
      # The Instrumentation class contains logic to detect and install the Gruf instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
        end

        option :peer_service, default: nil, validate: :string
        option :grpc_ignore_methods, default: [], validate: :array
        option :log_requests_on_server, default: true, validate: :boolean
        option :log_requests_on_client, default: true, validate: :boolean
        option :span_name_server, default: nil, validate: :callable
        option :span_name_client, default: nil, validate: :callable
        option :exception_message, default: :short, validate: %i[short full]

        present do
          defined?(::Gruf)
        end

        private

        def require_dependencies
          require_relative 'interceptors/client'
          require_relative 'interceptors/server'
        end
      end
    end
  end
end
