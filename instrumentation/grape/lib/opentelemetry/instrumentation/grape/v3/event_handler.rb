# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../event_handler'

module OpenTelemetry
  module Instrumentation
    module Grape
      module V3
        # Event handler implementation for Grape < 4.0
        class EventHandler < Grape::EventHandler
          class << self
            private

            def request_method(endpoint)
              if endpoint.respond_to?(:options)
                opts = endpoint.options
                method = opts[:method]&.first if opts.is_a?(Hash)
                return method if method
              end

              if endpoint.respond_to?(:routes)
                route = endpoint.routes&.first
                return route.request_method if route.respond_to?(:request_method) && route.request_method
              end

              nil
            end

            def code_namespace(endpoint)
              if endpoint.respond_to?(:options)
                opts = endpoint.options
                owner = opts[:for] if opts.is_a?(Hash)
              end
              owner ||= endpoint.api if endpoint.respond_to?(:api)
              return unless owner

              base = owner.instance_variable_get(:@base) if owner.instance_variable_defined?(:@base)
              [owner.name, base&.to_s, owner.to_s].find { |value| value && !value.empty? }
            end

            def raw_endpoint_path(endpoint)
              return unless endpoint.respond_to?(:options)

              opts = endpoint.options
              Array(opts[:path]) if opts.is_a?(Hash) && opts[:path]
            end

            def route_namespace(route)
              ns = route.namespace if route.respond_to?(:namespace)
              return ns if ns && !ns.to_s.empty?
              return unless route.respond_to?(:options)

              opts = route.options
              opts[:namespace] if opts.is_a?(Hash)
            end

            def route_version(route)
              version = route.version if route.respond_to?(:version)
              if version.nil? && route.respond_to?(:options)
                opts = route.options
                version = opts[:version] if opts.is_a?(Hash)
              end
              version.is_a?(Array) ? version.first&.to_s : version&.to_s
            end

            def route_prefix(route)
              prefix = route.prefix if route.respond_to?(:prefix)
              if prefix.nil? && route.respond_to?(:options)
                opts = route.options
                prefix = opts[:prefix] if opts.is_a?(Hash)
              end
              prefix&.to_s
            end
          end
        end
      end
    end
  end
end
