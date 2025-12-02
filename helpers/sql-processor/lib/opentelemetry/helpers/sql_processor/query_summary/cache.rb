# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module QuerySummary
      # Cache provides thread-safe LRU caching for query summaries.
      #
      # Stores generated query summaries to avoid reprocessing identical queries.
      # Uses mutex synchronization for thread safety.
      #
      # @example
      #   cache = Cache.new
      #   cache.fetch("SELECT * FROM users") { "SELECT users" } # => "SELECT users"
      class Cache
        DEFAULT_SIZE = 1000

        def initialize(size: DEFAULT_SIZE)
          @cache = {}
          @cache_mutex = Mutex.new
          @cache_size = size
        end

        def fetch(key)
          @cache_mutex.synchronize do
            return @cache[key] if @cache.key?(key)

            result = yield
            evict_if_needed
            @cache[key] = result
            result
          end
        end

        private

        def configure(size: DEFAULT_SIZE)
          @cache_size = size
          @cache.clear if @cache.size > size
        end

        def clear
          @cache.clear
        end

        def evict_if_needed
          @cache.shift if @cache.size >= @cache_size
        end
      end
    end
  end
end
