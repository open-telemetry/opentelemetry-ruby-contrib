# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'
require_relative '../../../lib/opentelemetry/helpers/query_summary'

class QuerySummaryTest < Minitest::Test
  def self.load_fixture
    data = File.read("#{Dir.pwd}/test/fixtures/query_summary.json")
    JSON.parse(data)
  end

  def build_failure_message(query, expected_summary, actual_summary)
    "Failed to generate query summary correctly.\n" \
      "Input:    #{query}\n" \
      "Expected: #{expected_summary}\n" \
      "Actual:   #{actual_summary}\n"
  end

  load_fixture.each do |test_case|
    name = test_case['name']
    query = test_case['input']['query']
    expected_summary = test_case['expected']['db.query.summary']

    define_method(:"test_query_summary_#{name}") do
      actual_summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(query)
      message = build_failure_message(query, expected_summary, actual_summary)

      assert_equal(expected_summary, actual_summary, message)
    end
  end
end
