# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        # Module to prepend to Redis::Client for metrics
        module RedisV4ClientMetrics
          def self.prepended(base)
            base.prepend(OpenTelemetry::Instrumentation::Redis::Patches::MetricsHelpers)
          end

          def process(commands)
            return super unless (histogram = instrumentation.client_operation_duration_histogram)

            attributes = otel_base_attributes

            attributes['db.operation.name'] =
              if commands.length == 1
                commands[0][0].to_s
              else
                'PIPELINED'
              end

            otel_record_histogram(histogram, attributes) { super }
          end
        end
      end
    end
  end
end
