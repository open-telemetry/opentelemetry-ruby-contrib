# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0module OpenTelemetry

module OpenTelemetry
  module Helpers
    module QuerySummary
      # Cache provides thread-safe LRU caching for query summaries.
      #
      # Stores generated query summaries to avoid reprocessing identical queries.
      # Uses mutex synchronization for thread safety.
      #
      # @example
      #   Cache.fetch("SELECT * FROM users") { "SELECT users" } # => "SELECT users"
      class Cache
        DEFAULT_SIZE = 1000

        @cache = {}
        @cache_mutex = Mutex.new
        @cache_size = DEFAULT_SIZE

        def self.fetch(key)
          @cache_mutex.synchronize do
            return @cache[key] if @cache.key?(key)

            result = yield
            @cache.shift if @cache.size >= @cache_size
            @cache[key] = result
            result
          end
        end

        def self.configure(size: DEFAULT_SIZE)
          @cache_mutex.synchronize do
            @cache_size = size
            @cache.clear if @cache.size > size
          end
        end

        def self.store(key, value)
          @cache_mutex.synchronize do
            @cache.shift if @cache.size >= @cache_size
            @cache[key] = value
          end
        end
      end
    end
  end
end
