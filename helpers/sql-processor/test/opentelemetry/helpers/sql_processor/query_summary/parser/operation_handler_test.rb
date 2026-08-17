# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/operation_handler'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/token_processor'

class OperationHandlerTest < Minitest::Test
  # Use aliases for cleaner test code
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants
  OperationHandler = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::OperationHandler

  def test_identifier_like_with_identifier_token
    token = [:identifier, 'users']
    assert OperationHandler.identifier_like?(token)
  end

  def test_identifier_like_with_quoted_identifier_token
    token = [:quoted_identifier, '"users"']
    assert OperationHandler.identifier_like?(token)
  end

  def test_identifier_like_with_other_token_types
    refute OperationHandler.identifier_like?([:keyword, 'SELECT'])
    refute OperationHandler.identifier_like?([:string, "'test'"])
    refute OperationHandler.identifier_like?([:operator, '+'])
  end

  def test_handle_union_without_all
    tokens = [[:keyword, 'UNION']]

    result = OperationHandler.handle_union(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UNION'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_union_with_all
    tokens = [
      [:keyword, 'UNION'],
      [:keyword, 'ALL']
    ]

    result = OperationHandler.handle_union(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UNION ALL'],
      new_state: Constants::PARSING_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_union_with_non_all_following
    tokens = [
      [:keyword, 'UNION'],
      [:keyword, 'SELECT']
    ]

    result = OperationHandler.handle_union(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UNION'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_exec_operation_with_procedure_name
    tokens = [
      [:keyword, 'EXEC'],
      [:identifier, 'GetUserData']
    ]

    result = OperationHandler.handle_exec_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['EXEC GetUserData'],
      new_state: Constants::PARSING_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_exec_operation_without_procedure_name
    tokens = [[:keyword, 'EXEC']]

    result = OperationHandler.handle_exec_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['EXEC'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_exec_operation_with_quoted_procedure_name
    tokens = [
      [:keyword, 'EXEC'],
      [:quoted_identifier, '"GetUserData"']
    ]

    result = OperationHandler.handle_exec_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['EXEC "GetUserData"'],
      new_state: Constants::PARSING_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_update_operation_standard_case
    tokens = [
      [:keyword, 'UPDATE'],
      [:identifier, 'users'],
      [:keyword, 'SET']
    ]

    result = OperationHandler.handle_update_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UPDATE'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_update_operation_with_single_char_table_and_parentheses
    tokens = [
      [:keyword, 'UPDATE'],
      [:identifier, 'u'],
      [:keyword, 'SET'],
      [:identifier, 'col'],
      [:operator, '='],
      [:operator, '('],
      [:keyword, 'SELECT']
    ]

    result = OperationHandler.handle_update_operation(tokens[0], tokens, 0)

    # Should return just UPDATE due to single-char table + parenthesized constant
    expected = {
      processed: true,
      parts: ['UPDATE'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_update_operation_with_multi_char_table_and_parentheses
    tokens = [
      [:keyword, 'UPDATE'],
      [:identifier, 'users'],
      [:keyword, 'SET'],
      [:identifier, 'col'],
      [:operator, '='],
      [:operator, '('],
      [:keyword, 'SELECT']
    ]

    result = OperationHandler.handle_update_operation(tokens[0], tokens, 0)

    # Should include table name even with parenthesized constants
    expected = {
      processed: true,
      parts: ['UPDATE'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_update_operation_without_set
    tokens = [
      [:keyword, 'UPDATE'],
      [:identifier, 'users']
    ]

    result = OperationHandler.handle_update_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['UPDATE'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_table_operation_create_table
    tokens = [
      [:keyword, 'CREATE'],
      [:keyword, 'TABLE'],
      [:identifier, 'users']
    ]

    result = OperationHandler.handle_table_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['CREATE TABLE'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_table_operation_with_modifiers
    tokens = [
      [:keyword, 'CREATE'],
      [:keyword, 'UNIQUE'],
      [:keyword, 'INDEX'],
      [:identifier, 'idx_name']
    ]

    result = OperationHandler.handle_table_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['CREATE INDEX'],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 3 # Skip UNIQUE, land on INDEX
    }

    assert_equal expected, result
  end

  def test_handle_table_operation_without_object_type
    tokens = [
      [:keyword, 'CREATE'],
      [:identifier, 'something']
    ]

    result = OperationHandler.handle_table_operation(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['CREATE'],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_ddl_with_if_exists_drop_table
    tokens = [
      [:keyword, 'DROP'],
      [:keyword, 'TABLE'],
      [:keyword, 'IF'],
      [:keyword, 'EXISTS'],
      [:identifier, 'users']
    ]

    result = OperationHandler.handle_ddl_with_if_exists(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['DROP TABLE users'],
      new_state: Constants::PARSING_STATE,
      next_index: 5
    }

    assert_equal expected, result
  end

  def test_handle_ddl_with_if_exists_create_table_if_not_exists
    tokens = [
      [:keyword, 'CREATE'],
      [:keyword, 'TABLE'],
      [:keyword, 'IF'],
      [:keyword, 'NOT'],
      [:keyword, 'EXISTS'],
      [:identifier, 'users']
    ]

    result = OperationHandler.handle_ddl_with_if_exists(tokens[0], tokens, 0)

    expected = {
      processed: true,
      parts: ['CREATE TABLE users'],
      new_state: Constants::PARSING_STATE,
      next_index: 6
    }

    assert_equal expected, result
  end

  def test_handle_ddl_with_if_exists_no_match
    tokens = [
      [:keyword, 'DROP'],
      [:identifier, 'something']
    ]

    result = OperationHandler.handle_ddl_with_if_exists(tokens[0], tokens, 0)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_as_keyword_with_ddl_context
    tokens = [
      [:keyword, 'CREATE'],
      [:keyword, 'VIEW'],
      [:identifier, 'user_view'],
      [:keyword, 'AS'],
      [:keyword, 'SELECT']
    ]

    result = OperationHandler.handle_as_keyword(tokens[3], tokens, 3, Constants::PARSING_STATE)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 4
    }

    assert_equal expected, result
  end

  def test_handle_as_keyword_without_ddl_context
    tokens = [
      [:identifier, 'users'],
      [:keyword, 'AS'],
      [:identifier, 'u']
    ]

    result = OperationHandler.handle_as_keyword(tokens[1], tokens, 1, Constants::EXPECT_COLLECTION_STATE)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::EXPECT_COLLECTION_STATE,
      next_index: 2
    }

    assert_equal expected, result
  end

  def test_handle_as_keyword_with_mixed_case_ddl
    tokens = [
      [:keyword, 'create'],  # lowercase
      [:keyword, 'view'],
      [:identifier, 'user_view'],
      [:keyword, 'as'],      # lowercase
      [:keyword, 'select']
    ]

    result = OperationHandler.handle_as_keyword(tokens[3], tokens, 3, Constants::PARSING_STATE)

    expected = {
      processed: true,
      parts: [],
      new_state: Constants::DDL_BODY_STATE,
      next_index: 4
    }

    assert_equal expected, result
  end

  def test_handle_ddl_with_if_exists_incomplete_patterns
    # Test incomplete IF EXISTS pattern
    tokens = [
      [:keyword, 'DROP'],
      [:keyword, 'TABLE'],
      [:keyword, 'IF']
    ]

    result = OperationHandler.handle_ddl_with_if_exists(tokens[0], tokens, 0)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end

  def test_handle_ddl_with_if_exists_incomplete_if_not_exists
    # Test incomplete IF NOT EXISTS pattern
    tokens = [
      [:keyword, 'CREATE'],
      [:keyword, 'TABLE'],
      [:keyword, 'IF'],
      [:keyword, 'NOT']
    ]

    result = OperationHandler.handle_ddl_with_if_exists(tokens[0], tokens, 0)

    expected = {
      processed: false,
      parts: [],
      new_state: Constants::PARSING_STATE,
      next_index: 1
    }

    assert_equal expected, result
  end
end
