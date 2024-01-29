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
        option :propagate_with_link,      default: nil,   validate: :callable
        option :untraced_requests,        default: nil,   validate: :callable
        option :response_propagators,     default: [],    validate: :array
        # This option is only valid for applications using Rack 2.0 or greater
        option :use_rack_events,          default: true, validate: :boolean

        # Temporary Helper for Sinatra and ActionPack middleware to use during installation
        #
        # @example Default usage
        #   Rack::Builder.new do
        #     use *OpenTelemetry::Instrumentation::Rack::Instrumenation.instance.middleware_args
        #     run lambda { |_arg| [200, { 'Content-Type' => 'text/plain' }, body] }
        #   end
        # @return [Array] consisting of a middleware and arguments used in rack builders
        def middleware_args
          if config.fetch(:use_rack_events, false) == true && defined?(OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler)
            [::Rack::Events, [OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler.new]]
          else
            [OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware]
          end
        end

        private

        def require_dependencies
          require_relative 'middlewares/event_handler' if defined?(::Rack::Events)
          require_relative 'middlewares/tracer_middleware'
        end

        def config_options(user_config)
          config = super(user_config)
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
          config
        end

        def build_attribute_name(prefix, suffix)
          prefix + suffix.to_s.downcase.gsub(/[-\s]/, '_')
        end
      end
    end
  end
end
