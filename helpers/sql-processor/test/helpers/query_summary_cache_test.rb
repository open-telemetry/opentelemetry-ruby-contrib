# frozen_string_literal: true

# rubocop:disable Style/RedundantFetchBlock

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../test_helper'
require_relative '../../lib/opentelemetry/helpers/sql_processor/query_summary/cache'
require 'benchmark'

class CacheTest < Minitest::Test
  def setup
    @cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new
  end

  def test_fetch_returns_new_value_when_key_does_not_exist
    result = @cache.fetch('key1') { 'value1' }
    assert_equal 'value1', result
  end

  def test_fetch_returns_value_when_key_exists
    @cache.fetch('key1') { 'value1' }
    result = @cache.fetch('key1') { 'different_value' }

    assert_equal 'value1', result
  end

  def test_eviction_when_cache_size_exceeded
    small_cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new(size: 2)

    small_cache.fetch('key1') { 'value1' }
    small_cache.fetch('key2') { 'value2' }
    small_cache.fetch('key3') { 'value3' }

    result = small_cache.fetch('key1') { 'new_value1' }
    assert_equal 'new_value1', result
  end

  def test_cache_thread_safety
    threads = Array.new(10) do |i|
      Thread.new do
        @cache.fetch('shared_key') { "thread_#{i}_value" }
      end
    end

    results = threads.map(&:value)

    assert_equal 1, results.uniq.size
  end

  def test_empty_string
    @cache.fetch('') { 'empty_string_value' }

    assert_equal 'empty_string_value', @cache.fetch('')
  end

  def test_nil
    @cache.fetch(nil) { 'nil_value' }

    assert_equal 'nil_value', @cache.fetch(nil)
  end

  def test_large_key
    large_key = 'x' * 10_000
    @cache.fetch(large_key) { 'large_key_value' }
    assert_equal 'large_key_value', @cache.fetch(large_key)
  end

  def test_large_value
    very_large_value = 'y' * 100_000
    @cache.fetch('large_value_key') { very_large_value }
    assert_equal very_large_value, @cache.fetch('large_value_key')
  end

  def test_large_key_and_value
    very_large_key = 'z' * 50_000
    very_large_value = 'a' * 500_000
    @cache.fetch(very_large_key) { very_large_value }
    assert_equal very_large_value, @cache.fetch(very_large_key)
  end

  def test_performance_under_load
    duration = Benchmark.realtime do
      10_000.times do |i|
        # i % 100 ensures a mix of cache hits and misses
        @cache.fetch("perf_key_#{i % 100}") { "value_#{i}" }
      end
    end

    assert duration < 1.0, "Cache operations took too long: #{duration} seconds"
    assert_equal 'value_0', @cache.fetch('perf_key_0')
    assert_equal 'value_50', @cache.fetch('perf_key_50')
  end

  def test_concurrent_access
    thread_count = 50
    iterations_per_thread = 100

    threads = Array.new(thread_count) do |thread_id|
      Thread.new do
        iterations_per_thread.times do |i|
          key = "stress_key_#{i % 10}" # Multiple threads will compete for same keys
          @cache.fetch(key) { "thread_#{thread_id}_iteration_#{i}" }
        end
      end
    end

    threads.each(&:join)

    # Verify cache is still functional after stress test
    result = @cache.fetch('post_stress_key') { 'post_stress_value' }
    assert_equal 'post_stress_value', result
  end

  def test_lru_eviction_behavior
    lru_cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new(size: 2)

    # 1. Fill cache to capacity (A is LRU)
    lru_cache.fetch('A') { 'valueA' }
    lru_cache.fetch('B') { 'valueB' }
    # Cache state: [LRU] A -> B [MRU]

    # 2. Access A to make it Most Recently Used
    result = lru_cache.fetch('A') { 'should_not_execute' }
    assert_equal 'valueA', result
    # Cache state: [LRU] B -> A [MRU] (B is now the least recently used key)

    # 3. Add new key C - should evict B (the LRU key)
    lru_cache.fetch('C') { 'valueC' }
    # Cache state: [LRU] A -> C [MRU] (B is evicted, C is new MRU)

    # 4. Verify B was evicted (forces a cache miss)
    result = lru_cache.fetch('B') { 'newB' }
    assert_equal 'newB', result # Block should execute (cache miss)

    # New key B is added, which evicts A (now the LRU key)
    # Cache state: [LRU] C -> B [MRU] (A is evicted, B is new MRU)

    # 5. Verify C and B are present
    # Check C (was LRU, now should still be present)
    assert_equal 'valueC', lru_cache.fetch('C') { 'should_not_execute' }

    # Check B (just added)
    assert_equal 'newB', lru_cache.fetch('B') { 'should_not_execute' }
  end
end

# rubocop:enable Style/RedundantFetchBlock
