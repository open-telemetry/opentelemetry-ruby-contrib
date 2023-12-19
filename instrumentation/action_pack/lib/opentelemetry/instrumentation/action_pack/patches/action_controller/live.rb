# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Patches
        module ActionController
          # Module to append to ActionController::Live for instrumentation
          module Live
            def process_action(*)
              current_context = OpenTelemetry::Context.current

              # Unset thread local to avoid modifying stack array shared with parent thread
              Thread.current[:__opentelemetry_context_storage__] = nil

              attributes = {
                OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => self.class.name,
                OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => action_name
              }

              OpenTelemetry::Context.with_current(current_context) do
                Instrumentation.instance.tracer.in_span("#{self.class.name}##{action_name} stream", attributes: attributes) do
                  super
                end
              end
            end
          end
        end
      end
    end
  end
end
