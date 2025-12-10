require_relative '../test_helper'
require_relative '../../lib/opentelemetry/helpers/sql_processor/query_summary/cache'
require 'benchmark'

class CacheTest < Minitest::Test
  def setup
    @cache = OpenTelemetry::Helpers::QuerySummary::Cache.new
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
    small_cache = OpenTelemetry::Helpers::QuerySummary::Cache.new(size: 2)

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

    # Verify we can still retrieve a stressed key
    assert_equal 'thread_0_iteration_0', @cache.fetch('stress_key_0')
  end
end
