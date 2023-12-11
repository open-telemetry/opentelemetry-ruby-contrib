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
          end

          # Invoked by ActiveSupport::Notifications at the start of the instrumentation block
          #
          # @param _name [String] of the event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] the payload passed as a method argument
          # @return [Hash] the payload passed as a method argument
          def start(_name, _id, payload)
            rack_span = OpenTelemetry::Instrumentation::Rack.current_span

            request = payload[:request]

            rack_span.name = "#{payload[:controller]}##{payload[:action]}" unless request.env['action_dispatch.exception']

            attributes_to_append = {
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => String(payload[:controller]),
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(payload[:action])
            }

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
        end
      end
    end
  end
end
