# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Middlewares
        # Adapter for redis-client instrumentation interface
        module RedisClientMetrics
          def call(command, redis_config)
            return super unless (histogram = instrumentation.client_operation_duration_histogram)

            timed(histogram, command.first, redis_config) do
              super
            end
          end

          def call_pipelined(commands, redis_config)
            return super unless (histogram = instrumentation.client_operation_duration_histogram)

            timed(histogram, 'PIPELINE', redis_config) do
              super
            end
          end

          private

          def timed(histogram, operation_name, redis_config)
            t0 = monotonic_now

            yield.tap do
              duration = monotonic_now - t0

              histogram.record(duration, attributes: metric_attributes(redis_config, operation_name))
            end
          end

          def monotonic_now
            Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
          end

          def metric_attributes(redis_config, operation_name)
            attributes = {
              'db.system' => 'redis',
              'db.operation.name' => operation_name,
              'net.peer.name' => redis_config.host,
              'net.peer.port' => redis_config.port
            }

            attributes['db.redis.database_index'] = redis_config.db unless redis_config.db.zero?
            attributes['peer.service'] = instrumentation.config[:peer_service] if instrumentation.config[:peer_service]
            attributes.merge!(OpenTelemetry::Instrumentation::Redis.attributes)
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
