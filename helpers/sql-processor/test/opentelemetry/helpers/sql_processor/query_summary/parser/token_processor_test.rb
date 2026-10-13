# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/token_processor'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/ddl_handler'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/operation_handler'

class TokenProcessorTest < Minitest::Test
  # Use aliases for cleaner test code
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants
  TokenProcessor = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::TokenProcessor

  def test_identifier_like_with_identifier_token
    token = [:identifier, 'users']
    assert TokenProcessor.identifier_like?(token)
  end

  def test_identifier_like_with_quoted_identifier_token
    token = [:quoted_identifier, '"users"']
    assert TokenProcessor.identifier_like?(token)
  end

  def test_identifier_like_with_keyword_token
    token = [:keyword, 'SELECT']
    refute TokenProcessor.identifier_like?(token)
  end

  def test_identifier_like_with_string_token
    token = [:string, "'test'"]
    refute TokenProcessor.identifier_like?(token)
  end

  def test_can_be_table_name_with_table_objects
    assert TokenProcessor.can_be_table_name?('TABLE')
    assert TokenProcessor.can_be_table_name?('INDEX')
    assert TokenProcessor.can_be_table_name?('PROCEDURE')
    assert TokenProcessor.can_be_table_name?('VIEW')
    refute TokenProcessor.can_be_table_name?('SELECT')
    refute TokenProcessor.can_be_table_name?('INSERT')
  end

  def test_add_to_summary
    result = TokenProcessor.add_to_summary('SELECT', Constants::PARSING_STATE, 5)

    expected = {
      processed: true,
      parts: ['SELECT'],
      new_state: Constants::PARSING_STATE,
      next_index: 5
    }

    assert_equal expected, result
  end

  def test_expect_table_names_next
    result = TokenProcessor.expect_table_names_next(3)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 3
    }

    assert_equal expected, result
  end

  def test_not_processed
    result = TokenProcessor.not_processed(Constants::PARSING_STATE, 2)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_collection_operator
    token = ['(', '(']
    result = TokenProcessor.handle_collection_operator(token, Constants::EXPECT_COLLECTION_STATE, 4)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 5
    }

    assert_equal expected, result
  end

  def test_return_to_normal_parsing
    token = [:keyword, 'WHERE']
    result = TokenProcessor.return_to_normal_parsing(token, 6)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 7
    }

    assert_equal expected, result
  end

  def test_process_token_in_ddl_body_state
    token = [:keyword, 'SELECT']
    tokens = [token]

    result = TokenProcessor.process_token(token, tokens, 0, state: Constants::DDL_BODY_STATE)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_main_operation_with_select
    token = [:keyword, 'SELECT']
    tokens = [token]

    result = TokenProcessor.process_main_operation(token, tokens, 0, state: Constants::PARSING_STATE, in_clause_context: false)

    expected = {
      processed: true,
      parts: ['SELECT'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_main_operation_with_from
    token = [:keyword, 'FROM']
    tokens = [token]

    result = TokenProcessor.process_main_operation(token, tokens, 0, state: Constants::PARSING_STATE, in_clause_context: false)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_main_operation_with_in_clause_context
    token = [:keyword, 'SELECT']
    tokens = [token]

    result = TokenProcessor.process_main_operation(token, tokens, 0, state: Constants::PARSING_STATE, in_clause_context: true)

    # Should return not processed when in clause context
    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_main_operation_with_with_openjson
    # Test WITH in OPENJSON context should be skipped
    tokens = [
      [:keyword, 'OPENJSON'],
      [:operator, '('],
      [:string, "'data'"],
      [:operator, ')'],
      [:keyword, 'WITH']
    ]
    with_token = tokens[4]

    result = TokenProcessor.process_main_operation(with_token, tokens, 4, state: Constants::PARSING_STATE, in_clause_context: false)

    # Should return not processed for OPENJSON WITH
    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 5
    }

    assert_equal expected, result
  end

  def test_process_main_operation_with_regular_with
    token = [:keyword, 'WITH']
    tokens = [token]

    result = TokenProcessor.process_main_operation(token, tokens, 0, state: Constants::PARSING_STATE, in_clause_context: false)

    # Regular WITH should be processed as collection operation
    expected = {
      processed: true,
      parts: ['WITH'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_collection_token_not_in_collection_state
    token = [:identifier, 'users']
    tokens = [token]

    result = TokenProcessor.process_collection_token(token, tokens, 0, state: Constants::PARSING_STATE, in_clause_context: false)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_collection_token_with_as_keyword
    token = [:keyword, 'AS']
    tokens = [token]

    result = TokenProcessor.process_collection_token(token, tokens, 0, state: Constants::EXPECT_COLLECTION_STATE, in_clause_context: false)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_collection_token_with_operator
    token = [:operator, '(']
    tokens = [token]

    result = TokenProcessor.process_collection_token(token, tokens, 0, state: Constants::EXPECT_COLLECTION_STATE, in_clause_context: false)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_collection_token_with_where_keyword
    token = [:keyword, 'WHERE']
    tokens = [token]

    result = TokenProcessor.process_collection_token(token, tokens, 0, state: Constants::EXPECT_COLLECTION_STATE, in_clause_context: false)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_process_token_falls_through_to_collection_processing
    # Create a token that won't match main operation processing but will match collection
    token = [:identifier, 'users']
    tokens = [token]

    result = TokenProcessor.process_token(token, tokens, 0,
                                          state: Constants::EXPECT_COLLECTION_STATE,
                                          in_clause_context: false)

    # Should be processed by collection token processing (calls DdlHandler)
    assert result[:processed], 'Token should be processed by collection processing'
    assert_equal Constants::PARSING_STATE, result[:new_state]
  end

  def test_process_token_returns_not_processed_when_no_match
    # Create a token that matches neither main operation nor collection processing
    token = [:unknown_type, 'unknown']
    tokens = [token]

    result = TokenProcessor.process_token(token, tokens, 0,
                                          state: Constants::PARSING_STATE,
                                          in_clause_context: false)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end
end
