# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/constants'
require_relative '../../../../../../lib/opentelemetry/helpers/sql_processor/query_summary/parser/summary_consolidator'

class SummaryConsolidatorTest < Minitest::Test
  # Use aliases for cleaner test code
  Constants = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::Constants
  SummaryConsolidator = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Parser::SummaryConsolidator

  def test_collect_table_names_from_position_basic
    summary_parts = %w[users orders UNION]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal %w[users orders], table_names
    assert_equal 2, next_index
  end

  def test_collect_table_names_from_position_stops_at_main_operation
    summary_parts = %w[users orders SELECT products]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal %w[users orders], table_names
    assert_equal 2, next_index
  end

  def test_collect_table_names_from_position_stops_at_union
    summary_parts = %w[users orders UNION SELECT]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal %w[users orders], table_names
    assert_equal 2, next_index
  end

  def test_collect_table_names_from_position_stops_at_table_operation
    summary_parts = %w[users CREATE TABLE]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal ['users'], table_names
    assert_equal 1, next_index
  end

  def test_collect_table_names_from_position_empty_result
    summary_parts = %w[SELECT users]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal [], table_names
    assert_equal 0, next_index
  end

  def test_collect_table_names_from_position_to_end
    summary_parts = %w[users orders]

    table_names, next_index = SummaryConsolidator.collect_table_names_from_position(summary_parts, 0)

    assert_equal %w[users orders], table_names
    assert_equal 2, next_index
  end

  def test_process_union_chain_simple
    summary_parts = %w[UNION SELECT orders]
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    assert_equal %w[users orders], table_names
    assert_equal 3, next_index
  end

  def test_process_union_chain_with_all
    summary_parts = %w[UNION ALL SELECT orders]
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    assert_equal %w[users orders], table_names
    assert_equal 4, next_index
  end

  def test_process_union_chain_multiple_unions
    summary_parts = %w[UNION SELECT orders UNION SELECT products]
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    assert_equal %w[users orders products], table_names
    assert_equal 6, next_index
  end

  def test_process_union_chain_union_without_select
    summary_parts = %w[UNION FROM orders]
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    # Should break the chain when UNION is not followed by SELECT
    assert_equal ['users'], table_names
    assert_equal 1, next_index
  end

  def test_process_union_chain_no_union
    summary_parts = ['WHERE', 'id', '=', '1']
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    # Should not process anything if no UNION found
    assert_equal ['users'], table_names
    assert_equal 0, next_index
  end

  def test_process_union_chain_mixed_with_union_all
    summary_parts = %w[UNION SELECT orders UNION ALL SELECT products]
    table_names = ['users']

    next_index = SummaryConsolidator.process_union_chain(summary_parts, 0, table_names)

    assert_equal %w[users orders products], table_names
    assert_equal 7, next_index
  end

  def test_consolidate_union_queries_simple_case
    summary_parts = %w[SELECT users UNION SELECT orders]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal %w[SELECT users orders], result
  end

  def test_consolidate_union_queries_with_union_all
    summary_parts = %w[SELECT users UNION ALL SELECT orders]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal %w[SELECT users orders], result
  end

  def test_consolidate_union_queries_multiple_unions
    summary_parts = %w[SELECT users UNION SELECT orders UNION SELECT products]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal %w[SELECT users orders products], result
  end

  def test_consolidate_union_queries_no_unions
    summary_parts = ['SELECT', 'users', 'WHERE', 'id', '=', '1']

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal ['SELECT', 'users', 'WHERE', 'id', '=', '1'], result
  end

  def test_consolidate_union_queries_non_select_operations
    summary_parts = %w[INSERT INTO users VALUES]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal %w[INSERT INTO users VALUES], result
  end

  def test_consolidate_union_queries_mixed_operations
    summary_parts = %w[SELECT users UNION SELECT orders INSERT INTO audit]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal %w[SELECT users orders INSERT INTO audit], result
  end

  def test_consolidate_union_queries_duplicate_table_names
    summary_parts = %w[SELECT users UNION SELECT users]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    # Should use .uniq to prevent "SELECT users users"
    assert_equal %w[SELECT users], result
  end

  def test_consolidate_union_queries_multiple_tables_with_duplicates
    summary_parts = %w[SELECT users orders UNION SELECT users products]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    # Should deduplicate table names
    assert_equal %w[SELECT users orders products], result
  end

  def test_consolidate_union_queries_select_without_enough_following_parts
    summary_parts = %w[SELECT users]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    # Should handle SELECT at end gracefully
    assert_equal %w[SELECT users], result
  end

  def test_consolidate_union_queries_complex_scenario
    summary_parts = %w[
      WITH cte AS
      SELECT users orders UNION ALL SELECT products customers
      INSERT INTO log
    ]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    expected = %w[
      WITH cte AS
      SELECT users orders products customers
      INSERT INTO log
    ]

    assert_equal expected, result
  end

  def test_consolidate_union_queries_empty_input
    summary_parts = []

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal [], result
  end

  def test_consolidate_union_queries_single_select
    summary_parts = ['SELECT']

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    assert_equal ['SELECT'], result
  end

  def test_consolidate_union_queries_incomplete_union_chain
    summary_parts = %w[SELECT users UNION FROM orders]

    result = SummaryConsolidator.consolidate_union_queries(summary_parts)

    # Should handle incomplete UNION chain (UNION not followed by SELECT)
    assert_equal %w[SELECT users FROM orders], result
  end
end
