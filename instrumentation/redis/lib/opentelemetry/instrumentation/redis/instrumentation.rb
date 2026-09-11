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
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_client_#{patch_type}")
        end

        present do
          defined?(::Redis) || defined?(::RedisClient)
        end

        option :peer_service,                 default: nil,   validate: :string
        option :trace_root_spans,             default: true,  validate: :boolean
        option :db_statement,                 default: :obfuscate, validate: %I[omit include obfuscate]

        private

        def determine_semconv
          stability_opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', '')
          values = stability_opt_in.split(',').map(&:strip)

          if values.include?('database/dup')
            'dup'
          elsif values.include?('database')
            'stable'
          else
            'old'
          end
        end

        def require_dependencies_old
          require_relative 'patches/old/redis_v4_client' if defined?(::Redis) && ::Redis::VERSION < '5'
          require_relative 'middlewares/old/redis_client' if defined?(::RedisClient)
        end

        def require_dependencies_stable
          require_relative 'patches/stable/redis_v4_client' if defined?(::Redis) && ::Redis::VERSION < '5'
          require_relative 'middlewares/stable/redis_client' if defined?(::RedisClient)
        end

        def require_dependencies_dup
          require_relative 'patches/dup/redis_v4_client' if defined?(::Redis) && ::Redis::VERSION < '5'
          require_relative 'middlewares/dup/redis_client' if defined?(::RedisClient)
        end

        def patch_client_old
          ::RedisClient.register(Middlewares::Old::RedisClientInstrumentation) if defined?(::RedisClient)
          ::Redis::Client.prepend(Patches::Old::RedisV4Client) if defined?(::Redis) && ::Redis::VERSION < '5'
        end

        def patch_client_stable
          ::RedisClient.register(Middlewares::Stable::RedisClientInstrumentation) if defined?(::RedisClient)
          ::Redis::Client.prepend(Patches::Stable::RedisV4Client) if defined?(::Redis) && ::Redis::VERSION < '5'
        end

        def patch_client_dup
          ::RedisClient.register(Middlewares::Dup::RedisClientInstrumentation) if defined?(::RedisClient)
          ::Redis::Client.prepend(Patches::Dup::RedisV4Client) if defined?(::Redis) && ::Redis::VERSION < '5'
        end
      end
    end
  end
end
