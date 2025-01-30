# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../patches/metrics_helpers'

module OpenTelemetry
  module Instrumentation
    module Redis
      module Middlewares
        # Adapter for redis-client instrumentation interface
        module RedisClientMetrics
          def self.included(base)
            base.include(OpenTelemetry::Instrumentation::Redis::Patches::MetricsHelpers)
          end

          def call(command, redis_config)
            return super unless (histogram = instrumentation.client_operation_duration_histogram)

            attributes = metric_attributes(redis_config, command.first)
            otel_record_histogram(histogram, attributes) do
              super
            end
          end

          def call_pipelined(commands, redis_config)
            return super unless (histogram = instrumentation.client_operation_duration_histogram)

            attributes = metric_attributes(redis_config, 'PIPELINED')
            otel_record_histogram(histogram, attributes) do
              super
            end
          end

          private

          def metric_attributes(redis_config, operation_name)
            attributes = span_attributes(redis_config)
            attributes['db.operation.name'] = operation_name
            attributes
          end

          def instrumentation
            Redis::Instrumentation.instance
          end
        end
      end
    end
  end
end
