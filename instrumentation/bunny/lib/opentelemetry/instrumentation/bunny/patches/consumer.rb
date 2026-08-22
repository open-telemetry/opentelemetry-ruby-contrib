# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      module Patches
        # The Consumer module contains the instrumentation patch for the Consumer class
        module Consumer
          def call(delivery_info, properties, payload)
            # `queue` may be a `Bunny::Queue` or a `String` (e.g. when a consumer is
            # registered via `Bunny::Channel#basic_consume(queue_name, ...)` — the pattern
            # used by Hutch and other Bunny wrappers). Use the consumer's `channel`
            # attribute directly to avoid `NoMethodError: undefined method 'channel'
            # for an instance of String`.
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_process_span(channel, tracer, delivery_info, properties) do
              super
            end
          end

          private

          def tracer
            Bunny::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
