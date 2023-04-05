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
          # Handles the start of the endpoint_run.grape event (the parent event), where the context is attached
          def endpoint_run_start(_name, _id, payload)
            name = span_name(payload[:endpoint])
            span = tracer.start_span(name, attributes: run_attributes(payload), kind: :server)
            token = OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))

            payload.merge!(__opentelemetry_span: span, __opentelemetry_ctx_token: token)
          end

          # Handles the end of the endpoint_run.grape event (the parent event), where the context is detached
          def endpoint_run_finish(_name, _id, payload)
            span = payload.delete(:__opentelemetry_span)
            token = payload.delete(:__opentelemetry_ctx_token)
            return unless span && token

            handle_payload_exception(span, payload[:exception_object]) if payload[:exception_object]

            span.finish
            OpenTelemetry::Context.detach(token)
          end

          # Handles the endpoint_render.grape event
          def endpoint_render(_name, start, _finish, _id, payload)
            span = OpenTelemetry::Trace.current_span
            span.add_event('endpoint_render', attributes: {}, timestamp: start)
          end

          # Handles the endpoint_run_filters.grape events
          def endpoint_run_filters(_name, start, finish, _id, payload)
            filters = payload[:filters]
            type = payload[:type]

            # Prevent submitting empty filters
            return if (!filters || filters.empty?) || !type || (finish - start).zero?

            attributes = { 'grape.filter.type' => type.to_s }
            span = OpenTelemetry::Trace.current_span

            span.add_event('endpoint_run_filters', attributes: attributes, timestamp: start)
          end

          # Handles the format_response.grape event
          def format_response(_name, start, _finish, _id, payload)
            endpoint = payload[:env]['api.endpoint']
            name = span_name(endpoint)
            attributes = {
              'grape.operation' => 'format_response',
              'grape.formatter.type' => formatter_type(payload[:formatter])
            }
            tracer.in_span(name, attributes: attributes, start_timestamp: start, kind: :server) do |span|
              handle_payload_exception(span, payload[:exception_object]) if payload[:exception_object]
            end
          end

          private

          def tracer
            Grape::Instrumentation.instance.tracer
          end

          def span_name(endpoint)
            "#{request_method(endpoint)} #{path(endpoint)}"
          end

          def run_attributes(payload)
            endpoint = payload[:endpoint]
            path = path(endpoint)
            {
              'grape.operation' => 'endpoint_run',
              'code.namespace' => endpoint.options[:for]&.base.to_s,
              OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request_method(endpoint),
              OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE => path
            }
          end

          # ActiveSupport::Notifications will attach a `:exception_object` to the payload if there was
          # an error raised during the execution of the &block associated to the Notification.
          # This can be safely added to the span for tracing.
          def handle_payload_exception(span, exception)
            span.record_exception(exception)
            span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{exception.class}")
          end

          def request_method(endpoint)
            endpoint.options[:method]&.first
          end

          def path(endpoint)
            namespace = endpoint.routes.first.namespace
            version = endpoint.routes.first.options[:version] || ''
            prefix = endpoint.routes.first.options[:prefix]&.to_s || ''
            parts = [prefix, version] + namespace.split('/') + endpoint.options[:path]
            parts.reject { |p| p.blank? || p.eql?('/') }.join('/').prepend('/')
          end

          def formatter_type(formatter)
            basename = formatter.name.split('::').last
            # Convert from CamelCase to snake_case
            basename.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
          end
        end
      end
    end
  end
end
