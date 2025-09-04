require_relative '../../test_helper'
require_relative '../../../lib/opentelemetry/helpers/query_summary/cache'

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
end
