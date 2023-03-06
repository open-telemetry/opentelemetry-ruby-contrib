# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Rack
      # The Instrumentation class contains logic to detect and install the Rack
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          # TODO: move logic that configures allow lists here
          require_dependencies
        end

        present do
          defined?(::Rack)
        end

        option :allowed_request_headers,  default: [],    validate: :array
        option :allowed_response_headers, default: [],    validate: :array
        option :application,              default: nil,   validate: :callable
        option :record_frontend_span,     default: false, validate: :boolean
        option :untraced_endpoints,       default: [],    validate: :array
        option :url_quantization,         default: nil,   validate: :callable
        option :untraced_requests,        default: nil,   validate: :callable
        option :response_propagators,     default: [],    validate: :array

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
        end
      end
    end
  end
end
