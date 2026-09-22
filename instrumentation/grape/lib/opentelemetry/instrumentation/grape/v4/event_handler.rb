# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../event_handler'

module OpenTelemetry
  module Instrumentation
    module Grape
      module V4
        # Event handler implementation for Grape >= 4.0
        class EventHandler < Grape::EventHandler
          class << self
            private

            def request_method(endpoint)
              if endpoint.instance_variable_defined?(:@config)
                config = endpoint.instance_variable_get(:@config)
                return config.http_methods&.first if config.respond_to?(:http_methods)
              end

              if endpoint.respond_to?(:routes)
                route = endpoint.routes&.first
                return route.request_method if route.respond_to?(:request_method) && route.request_method
              end

              nil
            end

            def code_namespace(endpoint)
              if endpoint.instance_variable_defined?(:@config)
                config = endpoint.instance_variable_get(:@config)
                owner = config.api if config.respond_to?(:api)
                owner ||= config.for if config.respond_to?(:for)
              end
              owner ||= endpoint.api if endpoint.respond_to?(:api)
              return unless owner

              base = owner.instance_variable_get(:@base) if owner.instance_variable_defined?(:@base)
              [owner.name, base&.to_s, owner.to_s].find { |value| value && !value.empty? }
            end

            def raw_endpoint_path(endpoint)
              return unless endpoint.instance_variable_defined?(:@config)

              config = endpoint.instance_variable_get(:@config)
              Array(config.path) if config.respond_to?(:path) && config.path
            end

            def route_namespace(route)
              route.namespace if route.respond_to?(:namespace)
            end

            def route_version(route)
              return unless route.respond_to?(:version)

              version = route.version
              version.is_a?(Array) ? version.first&.to_s : version&.to_s
            end

            def route_prefix(route)
              route.prefix&.to_s if route.respond_to?(:prefix)
            end
          end
        end
      end
    end
  end
end
