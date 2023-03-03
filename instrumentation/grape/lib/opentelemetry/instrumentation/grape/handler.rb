# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      # This class subscribes to the generated ActiveSupport notifications and generates spans based on them.
      class Handler
        SUBSCRIPTIONS = {
          endpoint_run: 'endpoint_run.grape',
          endpoint_render: 'endpoint_render.grape',
          endpoint_run_filters: 'endpoint_run_filters.grape'
        }.freeze

        class << self
          def subscribe
            SUBSCRIPTIONS.each do |subscriber_method, event|
              ::ActiveSupport::Notifications.subscribe(event) do |*args|
                method(subscriber_method).call(*args)
              end
            end
          end

          private

          def endpoint_run(name, start, finish, id, payload)
            # TODO: check span.name and span.type, and set service.name
            env = payload.fetch(:env)
            # TODO: see if we need to use symbol_key_getter instead
            # Taken from https://github.com/open-telemetry/opentelemetry-ruby/blob/main/examples/http/server.rb
            extracted_context = OpenTelemetry.propagation.extract(
              env,
              getter: OpenTelemetry::Common::Propagation.rack_env_getter
            )
            OpenTelemetry::Context.with_current(extracted_context) do
              tracer.in_span(name, attributes: build_run_attributes(payload), kind: :server) {}
            end
          end

          def endpoint_render(name, start, finish, id, payload)
            attributes = {
              'component' => 'template',
              'operation' => 'endpoint_render'
            }
            tracer.in_span(name, attributes: attributes, kind: :server) {}
          end

          def endpoint_run_filters(name, start, finish, id, payload)
            filters = payload[:filters]
            type = payload[:type]

            # Prevent submitting empty filters
            zero_length = (finish - start).zero?
            return if (!filters || filters.empty?) || !type || zero_length

            attributes = {
              'component' => 'web',
              'operation' => 'endpoint_run_filters',
              'grape.filter.type' => type.to_s
            }
            tracer.in_span(name, attributes: attributes, kind: :server) {}
          end

          def build_run_attributes(payload)
            endpoint = payload.fetch(:endpoint)
            request_method = endpoint.options.fetch(:method).first
            path = endpoint_expand_path(endpoint)
            api_instance = endpoint.options[:for]
            # TODO: missing attributes? http.status_code, http.route?
            {
              'component' => 'web',
              'operation' => 'endpoint_run',
              'grape.route.endpoint' => api_instance.base.to_s,
              'grape.route.path' => path,
              'grape.route.method' => request_method,
              'http.method' => request_method,
              'http.url' => path
            }
          end

          def endpoint_expand_path(endpoint)
            # TODO: copied from ddog implementation, so we need to double check
            route_path = endpoint.options[:path]
            namespace = endpoint.routes.first&.namespace || ''

            parts = (namespace.split('/') + route_path).reject { |p| p.blank? || p.eql?('/') }
            parts.join('/').prepend('/')
          end

          def tracer
            Grape::Instrumentation.instance.tracer
          end

          def config
            Grape::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
