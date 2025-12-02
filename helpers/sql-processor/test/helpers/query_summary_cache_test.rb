# require_relative '../test_helper'
# require_relative '../../lib/opentelemetry/helpers/sql_processor/query_summary/cache'

# class CacheTest < Minitest::Test
#   def setup
#     @cache = OpenTelemetry::Helpers::QuerySummary::Cache.new
#   end

#   def test_fetch_returns_new_value_when_key_does_not_exist
#     result = @cache.fetch('key1') { 'value1' }
#     assert_equal 'value1', result
#   end

#   def test_fetch_returns_value_when_key_exists
#     @cache.fetch('key1') { 'value1' }
#     result = @cache.fetch('key1') { 'different_value' }

#     assert_equal 'value1', result
#   end

#   def test_eviction_when_cache_size_exceeded
#     small_cache = OpenTelemetry::Helpers::QuerySummary::Cache.new(size: 2)

#     small_cache.fetch('key1') { 'value1' }
#     small_cache.fetch('key2') { 'value2' }
#     small_cache.fetch('key3') { 'value3' }

#     result = small_cache.fetch('key1') { 'new_value1' }
#     assert_equal 'new_value1', result
#   end

#   def test_cache_thread_safety
#     threads = Array.new(10) do |i|
#       Thread.new do
#         @cache.fetch('shared_key') { "thread_#{i}_value" }
#       end
#     end

#     results = threads.map(&:value)

#     assert_equal 1, results.uniq.size
#   end

#   def test_empty_string
#     @cache.fetch('') { 'empty_string_value' }

#     assert_equal 'empty_string_value', @cache.fetch('')
#   end

#   def test_nil
#     @cache.fetch(nil) { 'nil_value' }

#     assert_equal 'nil_value', @cache.fetch(nil)
#   end
# end
