# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        # Cache provides thread-safe LRU caching for query summaries.
        #
        # Stores generated query summaries to avoid reprocessing identical queries.
        # When cache reaches maximum size, least recently used entries are evicted first (LRU).
        # Uses mutex synchronization for thread safety in concurrent applications.
        #
        # @example Basic usage
        #   cache = Cache.new(size: 500)
        #   cache.fetch("SELECT * FROM users") { "SELECT users" } # => "SELECT users"
        #   cache.fetch("SELECT * FROM users") { "won't execute" } # => "SELECT users" (cached)
        #
        class Cache
          DEFAULT_SIZE = 1000

          def initialize(size: DEFAULT_SIZE)
            @cache = {}
            @cache_mutex = Mutex.new
            @cache_size = size
          end

          # Retrieves cached value or computes and caches new value.
          #
          # @param key [Object] Cache key (typically SQL query string)
          # @yield Block to execute if key not found in cache
          # @return [Object] Cached value or result of block execution
          def fetch(key)
            @cache_mutex.synchronize do
              if (value = @cache.delete(key))
                return @cache[key] = value
              end

              result = yield
              evict_if_needed
              @cache[key] = result
            end
          end

          private

          def evict_if_needed
            @cache.shift if @cache.size >= @cache_size
          end
        end
      end
    end
  end
end
