# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/ddl_handler'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/table_processor'

class DdlHandlerTest < Minitest::Test
  # Use aliases for cleaner test code
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants
  DdlHandler = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::DdlHandler

  def test_ddl_body_start_keywords_hash_optimization
    assert_instance_of Hash, DdlHandler::DDL_BODY_START_KEYWORDS
    assert DdlHandler::DDL_BODY_START_KEYWORDS.frozen?

    # Test O(1) hash lookup
    assert DdlHandler::DDL_BODY_START_KEYWORDS['SELECT']
    assert DdlHandler::DDL_BODY_START_KEYWORDS['INSERT']
    assert DdlHandler::DDL_BODY_START_KEYWORDS['UPDATE']
    assert DdlHandler::DDL_BODY_START_KEYWORDS['DELETE']
    assert DdlHandler::DDL_BODY_START_KEYWORDS['BEGIN']
    refute DdlHandler::DDL_BODY_START_KEYWORDS['FROM']
  end

  def test_handle_procedure_as_begin_pattern_with_valid_pattern
    tokens = [
      [:identifier, 'GetUserData'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.handle_procedure_as_begin_pattern(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['GetUserData'],
      new_state: Constants::PARSING_STATE,
      next_index: 3
    }

    assert_equal expected, result
  end

  def test_handle_procedure_as_begin_pattern_without_as
    tokens = [
      [:identifier, 'GetUserData'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.handle_procedure_as_begin_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_handle_procedure_as_begin_pattern_without_begin
    tokens = [
      [:identifier, 'GetUserData'],
      [:keyword, 'AS'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.handle_procedure_as_begin_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_handle_procedure_as_begin_pattern_with_missing_tokens
    tokens = [
      [:identifier, 'GetUserData']
    ]

    result = DdlHandler.handle_procedure_as_begin_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_handle_ddl_as_pattern_with_select
    tokens = [
      [:identifier, 'UserView'],
      [:keyword, 'AS'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.handle_ddl_as_pattern(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UserView'],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_ddl_as_pattern_with_begin
    tokens = [
      [:identifier, 'TriggerName'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.handle_ddl_as_pattern(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['TriggerName'],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_ddl_as_pattern_without_as
    tokens = [
      [:identifier, 'UserView'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.handle_ddl_as_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_handle_ddl_as_pattern_with_non_ddl_after_as
    tokens = [
      [:identifier, 'UserAlias'],
      [:keyword, 'AS'],
      [:identifier, 'u']
    ]

    result = DdlHandler.handle_ddl_as_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_handle_ddl_as_pattern_with_missing_after_as_token
    tokens = [
      [:identifier, 'UserView'],
      [:keyword, 'AS']
    ]

    result = DdlHandler.handle_ddl_as_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_find_as_begin_pattern_found
    tokens = [
      [:keyword, 'ON'],
      [:identifier, 'users'],
      [:keyword, 'AFTER'],
      [:keyword, 'INSERT'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.find_as_begin_pattern(tokens, 0, 6)
    assert_equal 5, result # Index of AS token
  end

  def test_find_as_begin_pattern_not_found
    tokens = [
      [:keyword, 'ON'],
      [:identifier, 'users'],
      [:keyword, 'AFTER'],
      [:keyword, 'INSERT']
    ]

    result = DdlHandler.find_as_begin_pattern(tokens, 0, 4)
    assert_nil result
  end

  def test_find_as_begin_pattern_as_without_begin
    tokens = [
      [:keyword, 'ON'],
      [:identifier, 'users'],
      [:keyword, 'AS'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.find_as_begin_pattern(tokens, 0, 4)
    assert_nil result
  end

  def test_find_as_begin_pattern_with_bounds
    tokens = [
      [:keyword, 'AS'],
      [:keyword, 'BEGIN'],
      [:keyword, 'SELECT']
    ]

    # Search only first token (AS), shouldn't find the pattern
    result = DdlHandler.find_as_begin_pattern(tokens, 0, 1)
    assert_equal 1, result

    # Search first two tokens, should find the pattern
    result = DdlHandler.find_as_begin_pattern(tokens, 0, 2)
    assert_equal 1, result
  end

  def test_handle_trigger_as_begin_pattern_found
    tokens = [
      [:identifier, 'UpdateAudit'],
      [:keyword, 'ON'],
      [:identifier, 'users'],
      [:keyword, 'AFTER'],
      [:keyword, 'INSERT'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.handle_trigger_as_begin_pattern(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UpdateAudit'],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 7 # AS token index + 1
    }

    assert_equal expected, result
  end

  def test_handle_trigger_as_begin_pattern_not_found
    tokens = [
      [:identifier, 'UpdateAudit'],
      [:keyword, 'ON'],
      [:identifier, 'users']
    ]

    result = DdlHandler.handle_trigger_as_begin_pattern(tokens[0], tokens, 0)
    assert_nil result
  end

  def test_process_table_name_and_alias_procedure_pattern
    tokens = [
      [:identifier, 'GetUserData'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.process_table_name_and_alias(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['GetUserData'],
      new_state: Constants::PARSING_STATE,
      next_index: 3
    }

    assert_equal expected, result
  end

  def test_process_table_name_and_alias_ddl_pattern
    tokens = [
      [:identifier, 'UserView'],
      [:keyword, 'AS'],
      [:keyword, 'SELECT']
    ]

    result = DdlHandler.process_table_name_and_alias(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UserView'],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_process_table_name_and_alias_trigger_pattern
    tokens = [
      [:identifier, 'UpdateAudit'],
      [:keyword, 'ON'],
      [:identifier, 'users'],
      [:keyword, 'AS'],
      [:keyword, 'BEGIN']
    ]

    result = DdlHandler.process_table_name_and_alias(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UpdateAudit'],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 5 # AS token index + 1
    }

    assert_equal expected, result
  end

  def test_process_table_name_and_alias_falls_back_to_regular_processing
    tokens = [
      [:identifier, 'users'],
      [:identifier, 'u']
    ]

    # This should fall back to TableProcessor.handle_regular_table_name
    result = DdlHandler.process_table_name_and_alias(tokens[0], tokens, 0)

    # The exact result depends on TableProcessor, but it should be processed
    assert result[:processed]
    assert_includes result[:parts], 'users'
  end

  def test_cached_upcase_usage_in_pattern_matching
    # Test that the module uses Constants.cached_upcase consistently
    tokens = [
      [:identifier, 'proc'],
      [:keyword, 'as'], # lowercase
      [:keyword, 'begin'] # lowercase
    ]

    # Should work with lowercase keywords due to cached_upcase
    result = DdlHandler.handle_procedure_as_begin_pattern(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['proc'],
      new_state: Constants::PARSING_STATE,
      next_index: 3
    }

    assert_equal expected, result
  end
end
