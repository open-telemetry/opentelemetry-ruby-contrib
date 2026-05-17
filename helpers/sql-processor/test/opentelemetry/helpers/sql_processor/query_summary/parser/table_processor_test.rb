# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/table_processor'

class TableProcessorTest < Minitest::Test
  # Use aliases for cleaner test code
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants
  TableProcessor = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::TableProcessor

  def test_stop_keywords_hash_optimization
    assert_instance_of Hash, TableProcessor::STOP_KEYWORDS
    assert TableProcessor::STOP_KEYWORDS.frozen?

    # Test O(1) hash lookup
    assert TableProcessor::STOP_KEYWORDS['WITH']
    assert TableProcessor::STOP_KEYWORDS['SET']
    assert TableProcessor::STOP_KEYWORDS['WHERE']
    assert TableProcessor::STOP_KEYWORDS['BEGIN']
    refute TableProcessor::STOP_KEYWORDS['FROM']
  end

  def test_clean_table_name_with_sql_server_brackets
    assert_equal 'users', TableProcessor.clean_table_name('[users]')
    assert_equal 'order_items', TableProcessor.clean_table_name('[order_items]')
  end

  def test_clean_table_name_with_mysql_backticks
    assert_equal 'users', TableProcessor.clean_table_name('`users`')
    assert_equal 'order_items', TableProcessor.clean_table_name('`order_items`')
  end

  def test_clean_table_name_with_standard_quotes_preserved
    assert_equal '"users"', TableProcessor.clean_table_name('"users"')
    assert_equal "'users'", TableProcessor.clean_table_name("'users'")
  end

  def test_clean_table_name_with_regular_name
    assert_equal 'users', TableProcessor.clean_table_name('users')
    assert_equal 'order_items', TableProcessor.clean_table_name('order_items')
  end

  def test_clean_table_name_with_short_strings
    assert_equal 'u', TableProcessor.clean_table_name('u')
    assert_equal '', TableProcessor.clean_table_name('')
    assert_equal '[', TableProcessor.clean_table_name('[')
    assert_equal '`', TableProcessor.clean_table_name('`')
  end

  def test_clean_table_name_with_mismatched_quotes
    assert_equal '[users`', TableProcessor.clean_table_name('[users`')
    assert_equal '`users]', TableProcessor.clean_table_name('`users]')
  end

  def test_calculate_alias_skip_with_as_keyword
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'AS'],
      [:identifier, 'u']
    ]

    result = TableProcessor.calculate_alias_skip(tokens, 0)
    assert_equal 2, result
  end

  def test_calculate_alias_skip_with_implicit_alias
    tokens = [
      [:identifier, 'users'],
      [:identifier, 'u']
    ]

    result = TableProcessor.calculate_alias_skip(tokens, 0)
    assert_equal 1, result
  end

  def test_calculate_alias_skip_with_no_alias
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'WHERE']
    ]

    result = TableProcessor.calculate_alias_skip(tokens, 0)
    assert_equal 0, result
  end

  def test_calculate_alias_skip_at_end_of_tokens
    tokens = [
      [:identifier, 'users']
    ]

    result = TableProcessor.calculate_alias_skip(tokens, 0)
    assert_equal 0, result
  end

  def test_calculate_alias_skip_with_lowercase_as
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'as'], # lowercase
      [:identifier, 'u']
    ]

    result = TableProcessor.calculate_alias_skip(tokens, 0)
    assert_equal 2, result
  end

  def test_handle_start_restart_pattern_with_with
    tokens = [
      [:identifier, 'seq'],
      [:keyword, 'START'],
      [:keyword, 'WITH'],
      [:number, '1']
    ]

    result = TableProcessor.handle_start_restart_pattern(tokens, 0, 0)
    assert_equal 2, result # Skip START and WITH
  end

  def test_handle_start_restart_pattern_without_with
    tokens = [
      [:identifier, 'seq'],
      [:keyword, 'START'],
      [:number, '1']
    ]

    result = TableProcessor.handle_start_restart_pattern(tokens, 0, 0)
    assert_equal 1, result # Skip just START
  end

  def test_handle_start_restart_pattern_with_current_skip
    tokens = [
      [:identifier, 'seq'],
      [:identifier, 's'], # alias (current_skip would be 1)
      [:keyword, 'START'],
      [:keyword, 'WITH'],
      [:number, '1']
    ]

    result = TableProcessor.handle_start_restart_pattern(tokens, 0, 1)
    assert_equal 2, result # Skip START and WITH
  end

  def test_determine_next_state_after_table_with_no_next_token
    tokens = [[:identifier, 'users']]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::PARSING_STATE,
      skip_count: 0,
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_after_table_with_comma
    tokens = [
      [:identifier, 'users'],
      [:operator, ','],
      [:identifier, 'orders']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::EXPECT_COLLECTION_STATE,
      skip_count: 1,
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_after_table_with_stop_keyword
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'WHERE']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::PARSING_STATE,
      skip_count: 1,
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_after_table_with_start_pattern
    tokens = [
      [:identifier, 'seq'],
      [:keyword, 'START'],
      [:keyword, 'WITH']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::PARSING_STATE,
      skip_count: 2,  # START + WITH
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_after_table_with_restart_pattern
    tokens = [
      [:identifier, 'seq'],
      [:keyword, 'RESTART'],
      [:keyword, 'WITH']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::PARSING_STATE,
      skip_count: 2,  # RESTART + WITH
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_after_table_with_other_keyword
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'JOIN']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 0)

    expected = {
      new_state: Constants::PARSING_STATE,
      skip_count: 0,
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_determine_next_state_with_initial_skip_count
    tokens = [
      [:identifier, 'users'],
      [:identifier, 'u'], # alias (skip_count = 1)
      [:operator, ',']
    ]

    result = TableProcessor.determine_next_state_after_table(tokens, 0, 1)

    expected = {
      new_state: Constants::EXPECT_COLLECTION_STATE,
      skip_count: 2, # 1 (alias) + 1 (comma)
      should_terminate: false
    }

    assert_equal expected, result
  end

  def test_handle_regular_table_name_basic
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'WHERE']
    ]

    result = TableProcessor.handle_regular_table_name(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['users'],
      new_state: Constants::PARSING_STATE,
      next_index: 2, # 0 + 1 (token) + 1 (WHERE skip)
      terminate_after_ddl: false
    }

    assert_equal expected, result
  end

  def test_handle_regular_table_name_with_alias
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'AS'],
      [:identifier, 'u'],
      [:keyword, 'WHERE']
    ]

    result = TableProcessor.handle_regular_table_name(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['users'],
      new_state: Constants::PARSING_STATE,
      next_index: 4, # 0 + 1 (token) + 2 (AS u) + 1 (WHERE skip)
      terminate_after_ddl: false
    }

    assert_equal expected, result
  end

  def test_handle_regular_table_name_with_brackets
    tokens = [
      [:identifier, '[users]'],
      [:keyword, 'WHERE']
    ]

    result = TableProcessor.handle_regular_table_name(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['users'], # brackets removed
      new_state: Constants::PARSING_STATE,
      next_index: 2,
      terminate_after_ddl: false
    }

    assert_equal expected, result
  end

  def test_handle_regular_table_name_with_comma_continuation
    tokens = [
      [:identifier, 'users'],
      [:operator, ','],
      [:identifier, 'orders']
    ]

    result = TableProcessor.handle_regular_table_name(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['users'],
      new_state: Constants::EXPECT_COLLECTION_STATE, # comma continues collection
      next_index: 2, # 0 + 1 (token) + 1 (comma skip)
      terminate_after_ddl: false
    }

    assert_equal expected, result
  end
end
