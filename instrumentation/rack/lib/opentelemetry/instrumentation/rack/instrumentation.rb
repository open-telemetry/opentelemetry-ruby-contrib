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
          require_dependencies
          configure_defaults
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
          require_relative 'middlewares/event_handler' if defined?(Rack::Events)
          require_relative 'middlewares/tracer_middleware'
        end

        def configure_defaults
          config[:allowed_rack_request_headers] = config[:allowed_request_headers].compact.each_with_object({}) do |header, memo|
            key = header.to_s.upcase.gsub(/[-\s]/, '_')
            case key
            when 'CONTENT_TYPE', 'CONTENT_LENGTH'
              memo[key] = build_attribute_name('http.request.header.', header)
            else
              memo["HTTP_#{key}"] = build_attribute_name('http.request.header.', header)
            end
          end

          config[:allowed_rack_response_headers] = config[:allowed_response_headers].each_with_object({}) do |header, memo|
            memo[header] = build_attribute_name('http.response.header.', header)
            memo[header.to_s.upcase] = build_attribute_name('http.response.header.', header)
          end

          config[:untraced_endpoints]&.compact!
        end

        def build_attribute_name(prefix, suffix)
          prefix + suffix.to_s.downcase.gsub(/[-\s]/, '_')
        end
      end
    end
  end
end
