# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Handlers
        # Action Controller handler to handle the notification from Active Support
        class ActionController
          # @param config [Hash] of instrumentation options
          def initialize(config)
            @config = config
            @span_naming = config.fetch(:span_naming)
          end

          # Invoked by ActiveSupport::Notifications at the start of the instrumentation block
          #
          # @param _name [String] of the event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] the payload passed as a method argument
          # @return [Hash] the payload passed as a method argument
          def start(_name, _id, payload)
            span_name, attributes = to_span_name_and_attributes(payload)

            span = OpenTelemetry::Instrumentation::Rack.current_span
            span.name = span_name
            span.add_attributes(attributes)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Invoked by ActiveSupport::Notifications at the end of the instrumentation block
          #
          # @param _name [String] of the event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] the payload passed as a method argument
          # @return [Hash] the payload passed as a method argument
          def finish(_name, _id, payload)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            span.record_exception(payload[:exception_object]) if payload[:exception_object]
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          # Extracts the span name and attributes from the payload
          #
          # @param payload [Hash] the payload passed from ActiveSupport::Notifications
          # @return [Array<String, Hash>] the span name and attributes
          def to_span_name_and_attributes(payload)
            request = payload[:request]
            http_route = request.route_uri_pattern if request.respond_to?(:route_uri_pattern)

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => String(payload[:controller]),
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(payload[:action])
            }
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE] = http_route if http_route
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] = request.filtered_path if request.filtered_path != request.fullpath

            if @span_naming == :semconv
              return ["#{request.method} #{http_route.gsub('(.:format)', '')}", attributes] if http_route

              return ["#{request.method} /#{payload.dig(:params, :controller)}/#{payload.dig(:params, :action)}", attributes]
            end

            ["#{payload[:controller]}##{payload[:action]}", attributes]
          end
        end
      end
    end
  end
end
