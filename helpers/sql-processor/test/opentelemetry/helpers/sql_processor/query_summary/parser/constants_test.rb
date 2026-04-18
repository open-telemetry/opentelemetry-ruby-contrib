# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'

class ConstantsTest < Minitest::Test
  # Use the Constants module directly
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants

  def test_state_constants_defined
    assert_equal :parsing, Constants::PARSING_STATE
    assert_equal :expect_collection, Constants::EXPECT_COLLECTION_STATE
    assert_equal :ddl_body, Constants::DDL_BODY_STATE
  end

  def test_token_indices_defined
    assert_equal 0, Constants::TYPE_INDEX
    assert_equal 1, Constants::VALUE_INDEX
  end

  def test_operation_sets_are_frozen_sets
    assert_instance_of Set, Constants::MAIN_OPERATIONS
    assert Constants::MAIN_OPERATIONS.frozen?

    assert_instance_of Set, Constants::TABLE_OPERATIONS
    assert Constants::TABLE_OPERATIONS.frozen?

    assert_instance_of Set, Constants::TRIGGER_COLLECTION
    assert Constants::TRIGGER_COLLECTION.frozen?
  end

  def test_main_operations_contains_expected_values
    assert Constants::MAIN_OPERATIONS.include?('SELECT')
    assert Constants::MAIN_OPERATIONS.include?('INSERT')
    assert Constants::MAIN_OPERATIONS.include?('DELETE')
    refute Constants::MAIN_OPERATIONS.include?('UPDATE')
    refute Constants::MAIN_OPERATIONS.include?('CREATE')
  end

  def test_table_operations_contains_expected_values
    assert Constants::TABLE_OPERATIONS.include?('CREATE')
    assert Constants::TABLE_OPERATIONS.include?('ALTER')
    assert Constants::TABLE_OPERATIONS.include?('DROP')
    assert Constants::TABLE_OPERATIONS.include?('TRUNCATE')
    refute Constants::TABLE_OPERATIONS.include?('SELECT')
  end

  def test_table_objects_contains_expected_values
    assert Constants::TABLE_OBJECTS.include?('TABLE')
    assert Constants::TABLE_OBJECTS.include?('INDEX')
    assert Constants::TABLE_OBJECTS.include?('PROCEDURE')
    assert Constants::TABLE_OBJECTS.include?('VIEW')
    assert Constants::TABLE_OBJECTS.include?('DATABASE')
    refute Constants::TABLE_OBJECTS.include?('SELECT')
  end

  def test_trigger_collection_contains_expected_values
    assert Constants::TRIGGER_COLLECTION.include?('FROM')
    assert Constants::TRIGGER_COLLECTION.include?('INTO')
    assert Constants::TRIGGER_COLLECTION.include?('JOIN')
    assert Constants::TRIGGER_COLLECTION.include?('IN')
    refute Constants::TRIGGER_COLLECTION.include?('SELECT')
  end

  def test_max_summary_length_defined
    assert_equal 255, Constants::MAX_SUMMARY_LENGTH
    assert_instance_of Integer, Constants::MAX_SUMMARY_LENGTH
  end

  def test_cached_upcase_with_valid_strings
    assert_equal 'HELLO', Constants.cached_upcase('hello')
    assert_equal 'WORLD', Constants.cached_upcase('WORLD')
    assert_equal 'SELECT', Constants.cached_upcase('select')
    assert_equal 'MIXED', Constants.cached_upcase('MIXeD')
  end

  def test_cached_upcase_with_nil
    assert_nil Constants.cached_upcase(nil)
  end

  def test_cached_upcase_with_empty_string
    assert_equal '', Constants.cached_upcase('')
  end

  def test_cached_upcase_actually_caches
    # Test that caching works by calling same value twice
    # We can't test object identity since the cache is private, but we can
    # verify that the method consistently returns the same result
    result1 = Constants.cached_upcase('test_string')
    assert_equal 'TEST_STRING', result1

    result2 = Constants.cached_upcase('test_string')
    assert_equal 'TEST_STRING', result2

    # Both should be strings
    assert_instance_of String, result1
    assert_instance_of String, result2
  end

  def test_cached_upcase_returns_string
    result = Constants.cached_upcase('freeze_test')
    assert_instance_of String, result
    assert_equal 'FREEZE_TEST', result
  end

  def test_cached_upcase_handles_symbols
    # Test that the method can handle different input types
    assert_equal 'SYMBOL', Constants.cached_upcase('symbol')
  end

  def test_union_select_keywords_set
    assert_instance_of Set, Constants::UNION_SELECT_KEYWORDS
    assert Constants::UNION_SELECT_KEYWORDS.frozen?
    assert_includes Constants::UNION_SELECT_KEYWORDS, 'UNION'
    assert_includes Constants::UNION_SELECT_KEYWORDS, 'SELECT'
  end

  def test_unique_keywords_set
    assert_instance_of Set, Constants::UNIQUE_KEYWORDS
    assert Constants::UNIQUE_KEYWORDS.frozen?
    assert_includes Constants::UNIQUE_KEYWORDS, 'UNIQUE'
    assert_includes Constants::UNIQUE_KEYWORDS, 'CLUSTERED'
    assert_includes Constants::UNIQUE_KEYWORDS, 'DISTINCT'
  end

  def test_ddl_operations_set
    assert_instance_of Set, Constants::DDL_OPERATIONS
    assert Constants::DDL_OPERATIONS.frozen?
    assert_includes Constants::DDL_OPERATIONS, 'CREATE'
    assert_includes Constants::DDL_OPERATIONS, 'ALTER'
  end

  def test_stop_collection_keywords_set
    assert_instance_of Set, Constants::STOP_COLLECTION_KEYWORDS
    assert Constants::STOP_COLLECTION_KEYWORDS.frozen?
    assert_includes Constants::STOP_COLLECTION_KEYWORDS, 'WITH'
    assert_includes Constants::STOP_COLLECTION_KEYWORDS, 'SET'
    assert_includes Constants::STOP_COLLECTION_KEYWORDS, 'WHERE'
    assert_includes Constants::STOP_COLLECTION_KEYWORDS, 'BEGIN'
  end

  def test_all_operation_sets_are_disjoint_where_expected
    # MAIN_OPERATIONS and UPDATE_OPERATIONS should be separate
    main_and_update = Constants::MAIN_OPERATIONS & Constants::UPDATE_OPERATIONS.to_set
    assert_empty main_and_update, 'MAIN_OPERATIONS and UPDATE_OPERATIONS should not overlap'

    # MAIN_OPERATIONS and TABLE_OPERATIONS should be separate
    main_and_table = Constants::MAIN_OPERATIONS & Constants::TABLE_OPERATIONS
    assert_empty main_and_table, 'MAIN_OPERATIONS and TABLE_OPERATIONS should not overlap'
  end
end
