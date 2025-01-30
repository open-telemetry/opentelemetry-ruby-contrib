# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      # The Instrumentation class contains logic to detect and install the Redis
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Redis) || defined?(::RedisClient)
        end

        option :peer_service,                 default: nil,   validate: :string
        option :trace_root_spans,             default: true,  validate: :boolean
        option :db_statement,                 default: :obfuscate, validate: %I[omit include obfuscate]
        option :metrics,                      default: false, validate: :boolean

        # https://opentelemetry.io/docs/specs/semconv/database/database-metrics/#metric-dbclientoperationduration
        histogram 'db.client.operation.duration',
                  attributes: { 'db.system' => 'redis' },
                  unit: 's',
                  explicit_bucket_boundaries: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10]

        def client_operation_duration_histogram
          histogram('db.client.operation.duration')
        end

        private

        def require_dependencies
          require_redis_client_dependencies
          require_redis_v4_dependencies
        end

        def require_redis_v4_dependencies
          return unless defined?(::Redis) && Gem::Version.new(Redis::VERSION) < Gem::Version.new('5.0.0')

          require_relative 'patches/redis_v4_client'
          require_relative 'patches/redis_v4_client_metrics'
        end

        def require_redis_client_dependencies
          return unless defined?(::RedisClient)

          require_relative 'middlewares/redis_client'
          require_relative 'middlewares/redis_client_metrics'
        end

        def patch_client
          patch_redis_v4_client
          patch_redis_client
        end

        def patch_redis_v4_client
          return unless defined?(::Redis) && Gem::Version.new(Redis::VERSION) < Gem::Version.new('5.0.0')

          ::Redis::Client.prepend(Patches::RedisV4Client)
          ::Redis::Client.prepend(Patches::RedisV4ClientMetrics) if metrics_defined?
        end

        # Applies to redis-client or redis >= 5
        def patch_redis_client
          return unless defined?(::RedisClient)

          ::RedisClient.register(Middlewares::RedisClientInstrumentation)
          ::RedisClient.register(Middlewares::RedisClientMetrics) if metrics_defined?
        end
      end
    end
  end
end
