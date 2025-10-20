# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.

require_relative '../test_helper'

class SqlObfuscationTest < Minitest::Test
  def test_named_arg_defaults_obfuscates
    sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
    expected = 'SELECT * from users where users.id = ? and users.email = ?'
    result = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql)

    assert_equal(expected, result)
  end

  def test_obfuscation_returns_message_when_limit_is_reached
    sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
    expected = 'SQL not obfuscated, query exceeds 42 characters'
    result = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql, obfuscation_limit: 42)

    assert_equal(expected, result)
  end

  def test_non_utf_8_encoded_string_obfuscates_with_mysql
    sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com\255'"
    expected = 'SELECT * from users where users.id = ? and users.email = ?'
    result = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql, adapter: :mysql)

    assert_equal(expected, result)
  end

  def test_non_utf_8_encoded_string_obfuscates_with_postgres
    sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com\255'"
    expected = 'SELECT * from users where users.id = ? and users.email = ?'
    result = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql, adapter: :postgres)

    assert_equal(expected, result)
  end

  def test_statement_with_emoji_encodes_utf_8_and_obfuscates
    sql = "SELECT * from users where users.id = 1 and users.email = 'test@😄.com'"
    expected = 'SELECT * from users where users.id = ? and users.email = ?'
    result = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql)

    assert_equal(expected, result)
  end

  # The following tests and their corresponding fixture are based on code from
  # the New Relic Ruby agent.
  # source: https://github.com/newrelic/newrelic-ruby-agent/blob/cb72bb5fab3fb318613421c86863a5ccdd2ff250/test/new_relic/agent/database/sql_obfuscation_test.rb

  FAILED_TO_OBFUSCATE_MESSAGE = 'Failed to obfuscate SQL query - quote characters remained after obfuscation'

  def build_failure_message(statement, dialect, acceptable_outputs, actual_output)
    msg = "Failed to obfuscate #{dialect} query correctly.\n"
    msg << "Input:    #{statement}\n"
    if acceptable_outputs.size == 1
      msg << "Expected: #{acceptable_outputs.first}\n"
    else
      msg << "Acceptable outputs:\n"
      acceptable_outputs.each do |output|
        msg << "          #{output}\n"
      end
    end
    msg << "Actual:   #{actual_output}\n"
    msg
  end

  def self.load_fixture
    data = File.read("#{Dir.pwd}/test/fixtures/sql_obfuscation.json")
    JSON.parse(data)
  end

  load_fixture.each do |test_case|
    name = test_case['name']
    query = test_case['sql']
    acceptable_outputs = test_case['obfuscated']
    dialects = test_case['dialects']

    # If the entire query is obfuscated because it's malformed, we use a
    # placeholder message instead of just '?', so add that to the acceptable
    # outputs.
    acceptable_outputs << FAILED_TO_OBFUSCATE_MESSAGE if test_case['malformed']

    dialects.each do |dialect|
      define_method(:"test_sql_obfuscation_#{name}_#{dialect}") do
        actual_obfuscated = OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(query, adapter: dialect.to_sym)
        message = build_failure_message(query, dialect, acceptable_outputs, actual_obfuscated)

        assert_includes(acceptable_outputs, actual_obfuscated, message)
      end
    end
  end
  ## End New Relic tests
end
