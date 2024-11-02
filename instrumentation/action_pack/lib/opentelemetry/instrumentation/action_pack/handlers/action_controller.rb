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
            rack_span = OpenTelemetry::Instrumentation::Rack.current_span
            set_span_name(rack_span, payload)
            attributes_to_append = {
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => String(payload[:controller]),
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(payload[:action])
            }

            request = payload[:request]
            attributes_to_append[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] = request.filtered_path if request.filtered_path != request.fullpath

            rack_span.add_attributes(attributes_to_append)
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
            rack_span = OpenTelemetry::Instrumentation::Rack.current_span
            rack_span.record_exception(payload[:exception_object]) if payload[:exception_object]
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          def set_span_name(span, payload)
            request = payload[:request]

            # This is a mess
            # I will refactor it to use a strategy pattern if we are happy with the span name
            span.name = if @span_naming == :semconv
                          if Rails.version >= Gem::Version.new('7.1')
                            "#{request.method} #{request.route_uri_pattern}"
                          else
                            "#{request.method} #{payload.dig(:params, :controller)}/#{payload[:action]}"
                          end
                        else
                          "#{payload[:controller]}##{payload[:action]}"
                        end
          end
        end
      end
    end
  end
end
