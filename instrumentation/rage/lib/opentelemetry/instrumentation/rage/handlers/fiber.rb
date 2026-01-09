# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rage
      module Handlers
        # The class uses Fiber storage to propagate OpenTelemetry context between fibers.
        class Fiber < ::Rage::Telemetry::Handler
          # Save the current OpenTelemetry context into Fiber local storage.
          # Application-level fibers spawned via `Fiber.schedule` will automatically inherit the storage.
          module Patch
            def schedule(&)
              ::Fiber[:__rage_otel_context] = OpenTelemetry::Context.current
              super
            end
          end

          def initialize
            super
            ::Fiber.singleton_class.prepend(Patch)
          end

          handle 'core.fiber.spawn', with: :propagate_otel_context

          def propagate_otel_context(&)
            OpenTelemetry::Context.with_current(::Fiber[:__rage_otel_context], &)
          end
        end
      end
    end
  end
end
