# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The Producer module contains the instrumentation patch the Producer#produce method
        module Producer
          def produce(value, topic:, key: nil, headers: {}, partition: nil, partition_key: nil, create_time: Time.now)
            attributes = {
              'messaging.system' => 'kafka',
              'messaging.destination' => topic,
              'messaging.destination_kind' => 'topic'
            }

            # If current span is recording, we use that context. Otherwise, we
            # extract context from headers.
            ctx = if OpenTelemetry::Trace.current_span.recording?
                    OpenTelemetry::Context.current
                  else
                    OpenTelemetry.propagation.extract(headers)
                  end

            OpenTelemetry::Context.with_current(ctx) do
              tracer.in_span("#{topic} send", attributes: attributes, kind: :producer) do
                OpenTelemetry.propagation.inject(headers)
                super
              end
            end
          end

          private

          def tracer
            RubyKafka::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
