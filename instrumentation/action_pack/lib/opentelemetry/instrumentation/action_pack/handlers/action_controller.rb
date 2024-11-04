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
            span = OpenTelemetry::Instrumentation::Rack.current_span
            request = payload[:request]
            http_route = request.route_uri_pattern if request.respond_to?(:route_uri_pattern)
            # This is a mess
            # I will refactor it to use a strategy pattern if we are happy with the span name
            span.name = if @span_naming == :semconv
                          if http_route
                            "#{request.method} #{http_route.gsub('(.:format)', '')}"
                          else
                            "#{request.method} #{payload.dig(:params, :controller)}/#{payload.dig(:params, :action)}"
                          end
                        else
                          "#{payload[:controller]}##{payload[:action]}"
                        end

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => String(payload[:controller]),
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(payload[:action])
            }
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_ROUTE] = http_route if http_route
            attributes[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] = request.filtered_path if request.filtered_path != request.fullpath

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
        end
      end
    end
  end
end
