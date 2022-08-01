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
            @processor.extend(BatchConsumer) if @processor.respond_to?(:process_batch)
          end

          # This module contains logic to patch Racecar::Consumer for batch operations
          module BatchConsumer
            def process_batch(messages)
              attributes = {
                'messaging.system' => 'kafka',
                'messaging.destination_kind' => 'topic',
                'messaging.kafka.message_count' => messages.size
              }

              links = messages.map do |message|
                span_context = OpenTelemetry::Trace.current_span(OpenTelemetry.propagation.extract(message.headers, getter: OpenTelemetry::Common::Propagation.symbol_key_getter)).context
                OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
              end
              links.compact!

              tracer.in_span('batch process', attributes: attributes, links: links, kind: :consumer) do
                super messages
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
