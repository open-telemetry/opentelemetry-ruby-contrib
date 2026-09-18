# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      # Handles the events instrumented with ActiveSupport notifications.
      # These handlers contain all the logic needed to create and connect spans.
      class EventHandler
        class << self
          # Handles the start of the endpoint_run event, modifying the parent Rack span
          # and recording it as a span event
          def endpoint_run(_name, start, _finish, _id, payload)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            endpoint = payload[:endpoint]
            span.name = span_name(endpoint)
            span.add_attributes(attributes_from_grape_endpoint(endpoint))

            span.add_event('grape.endpoint_run', timestamp: start)
            handle_payload_exception(span, payload[:exception_object]) if payload[:exception_object]
          end

          # Handles the endpoint_render event, recording it as a span event
          def endpoint_render(_name, start, _finish, _id, payload)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            span.add_event('grape.endpoint_render', timestamp: start)
          end

          # Handles the endpoint_run_filters events, recording them as a span event
          def endpoint_run_filters(_name, start, finish, _id, payload)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            filters = payload[:filters]
            type = payload[:type]

            # Prevent submitting empty filters
            return if (!filters || filters.empty?) || !type || (finish - start).zero?

            attributes = { 'grape.filter.type' => type.to_s }
            span.add_event('grape.endpoint_run_filters', attributes: attributes, timestamp: start)
          end

          # Handles the format_response event, recording it as a span event
          def format_response(_name, start, _finish, _id, payload)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            attributes = {
              'grape.formatter.type' => formatter_type(payload[:formatter])
            }
            span.add_event('grape.format_response', attributes: attributes, timestamp: start)
            handle_payload_exception(span, payload[:exception_object]) if payload[:exception_object]
          end

          private

          def span_name(endpoint)
            "#{request_method(endpoint)} #{path(endpoint)}"
          end

          def attributes_from_grape_endpoint(endpoint)
            attributes = {
              OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE => path(endpoint)
            }
            code_namespace = code_namespace(endpoint)
            attributes[OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE] = code_namespace if code_namespace
            attributes
          end

          # ActiveSupport::Notifications will attach a `:exception_object` to the payload if there was
          # an error raised during the execution of the &block associated to the Notification.
          def handle_payload_exception(span, exception)
            # Only record exceptions if they were not raised (i.e. do not have a status code in Grape)
            # or do not have a 5xx status code. These exceptions are recorded by Rack.
            # See instrumentation/rack/lib/opentelemetry/instrumentation/rack/middlewares/tracer_middleware.rb#L155
            return unless exception.respond_to?(:status) && ::Rack::Utils.status_code(exception.status) < 500

            span.record_exception(exception)
            span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{exception.class}")
          end

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

            return unless endpoint.instance_variable_defined?(:@config)

            config = endpoint.instance_variable_get(:@config)
            return unless config.respond_to?(:http_methods)

            config.http_methods&.first
          end

          def code_namespace(endpoint)
            if endpoint.respond_to?(:options)
              opts = endpoint.options
              owner = opts[:for] if opts.is_a?(Hash)
            end
            owner ||= endpoint.api if endpoint.respond_to?(:api)
            if owner.nil? && endpoint.instance_variable_defined?(:@config)
              config = endpoint.instance_variable_get(:@config)
              owner = config.api if config.respond_to?(:api)
              owner ||= config.for if config.respond_to?(:for)
            end
            return unless owner

            base = owner.instance_variable_get(:@base) if owner.instance_variable_defined?(:@base)
            [owner.name, base&.to_s, owner.to_s].find { |value| value && !value.empty? }
          end

          def path(endpoint)
            return '' unless endpoint.respond_to?(:routes)

            routes = endpoint.routes
            return '' unless routes && !routes.empty?

            route = routes.first

            endpoint_path = raw_endpoint_path(endpoint)
            return fallback_path_from_route(route) if endpoint_path.nil? || endpoint_path.empty?

            namespace = route_namespace(route)
            version = route_version(route)
            prefix = route_prefix(route)
            parts = [prefix, version] + namespace.to_s.split('/') + Array(endpoint_path)
            parts.reject { |p| p.nil? || p.to_s.empty? || p.to_s.eql?('/') }.join('/').prepend('/')
          end

          def raw_endpoint_path(endpoint)
            if endpoint.respond_to?(:options)
              opts = endpoint.options
              return Array(opts[:path]) if opts.is_a?(Hash) && opts[:path]
            end

            if endpoint.instance_variable_defined?(:@config)
              config = endpoint.instance_variable_get(:@config)
              return Array(config.path) if config.respond_to?(:path) && config.path
            end

            nil
          end

          def fallback_path_from_route(route)
            origin = route.origin if route.respond_to?(:origin) && route.origin
            origin ||= route.path if route.respond_to?(:path) && route.path
            return '' unless origin

            result = origin.to_s.split('(').first || ''
            version = route_version(route)
            result = result.gsub(':version', version) if version && !version.empty? && result.include?(':version')
            result.start_with?('/') ? result : "/#{result}"
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

          def formatter_type(formatter)
            return 'custom' unless built_in_grape_formatter?(formatter)

            basename = formatter.name.split('::').last
            # Convert from CamelCase to snake_case
            basename.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
          end

          def built_in_grape_formatter?(formatter)
            formatter.respond_to?(:name) && formatter.name.include?('Grape::Formatter')
          end
        end
      end
    end
  end
end
