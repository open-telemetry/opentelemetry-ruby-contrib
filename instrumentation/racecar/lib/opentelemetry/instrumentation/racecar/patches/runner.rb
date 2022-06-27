# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Racecar
      module Patches
        # This module contains logic to patch Racecar::Runner and its processors
        module Runner
          def initialize(*args, **kwargs)
            super
            @processor.extend(Consumer)
          end

          # This module contains logic to patch Racecar::Consumer
          module Consumer
            def process(message)
              attributes = {
                'messaging.system' => 'kafka',
                'messaging.destination' => message.topic,
                'messaging.destination_kind' => 'topic',
                'messaging.kafka.partition' => message.partition,
                'messaging.kafka.offset' => message.offset
              }

              attributes['messaging.kafka.message_key'] = message.key if message.key
              parent_context = OpenTelemetry.propagation.extract(message.headers, getter: OpenTelemetry::Common::Propagation.symbol_key_getter)
              span_context = OpenTelemetry::Trace.current_span(parent_context).context
              links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid?

              OpenTelemetry::Context.with_current(parent_context) do
                tracer.in_span("#{message.topic} process", links: links, attributes: attributes, kind: :consumer) do
                  super message
                end
              end
            end

            def tracer
              Racecar::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
