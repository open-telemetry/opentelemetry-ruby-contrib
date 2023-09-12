# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Patches
        module ActionController
          # Module to prepend to ActionController::Metal for instrumentation
          module Metal
            def dispatch(name, request, response)
              rack_span = OpenTelemetry::Instrumentation::Rack.current_span
              if rack_span.recording?
                rack_span.name = "#{self.class.name}##{name}" unless request.env['action_dispatch.exception']

                attributes_to_append = {
                  OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => self.class.name,
                  OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(name)
                }
                attributes_to_append[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] = request.filtered_path if request.filtered_path != request.fullpath
                rack_span.add_attributes(attributes_to_append)
              end

              super(name, request, response)
            rescue Exception => e # rubocop:disable Lint/RescueException
              rack_span.record_exception(e)
              raise
            end

            private

            def instrumentation_config
              ActionPack::Instrumentation.instance.config
            end
          end
        end
      end
    end
  end
end
