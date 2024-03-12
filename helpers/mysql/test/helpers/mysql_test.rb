# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Helpers::MySQL do
  describe '.database_span_name' do
    let(:sql) { 'SELECT * FROM users' }
    let(:operation) { 'operation' }
    let(:database_name) { 'database_name' }
    let(:config) { { span_name: span_name } }
    let(:database_span_name) { OpenTelemetry::Helpers::MySQL.database_span_name(sql, operation, database_name, config) }

    describe 'when config[:span_name] is :statement_type' do
      let(:span_name) { :statement_type }

      it 'returns the statement type' do
        assert_equal(database_span_name, 'select')
      end
    end

    describe 'when config[:span_name] is :db_name' do
      let(:span_name) { :db_name }

      it 'returns database name' do
        assert_equal(database_span_name, database_name)
      end
    end

    describe 'when config[:span_name] is :db_operation_and_name' do
      let(:span_name) { :db_operation_and_name }

      it 'returns db operation and name' do
        assert_equal(database_span_name, 'operation database_name')
      end
    end

    describe 'when config[:span_name] does not match a case' do
      let(:span_name) { 'something_unexpected' }

      it 'returns mysql' do
        assert_equal(database_span_name, 'mysql')
      end
    end

    describe 'when config[:span_name] is nil' do
      let(:span_name) { nil }

      it 'returns mysql' do
        assert_equal(database_span_name, 'mysql')
      end
    end
  end

  describe '.db_operation_and_name' do
    let(:operation) { 'operation' }
    let(:database_name) { 'database_name' }
    let(:db_operation_and_name) { OpenTelemetry::Helpers::MySQL.db_operation_and_name(operation, database_name) }

    describe 'when operation and database_name are present' do
      it 'returns a combination of the operation and database_name' do
        assert_equal(db_operation_and_name, 'operation database_name')
      end
    end

    describe 'when operation is nil' do
      let(:operation) { nil }

      it 'returns database_name' do
        assert_equal(db_operation_and_name, database_name)
      end
    end

    describe 'when database_name is nil' do
      let(:database_name) { nil }

      it 'returns the operation name' do
        assert_equal(db_operation_and_name, operation)
      end
    end

    describe 'when both database_name and operation are nil' do
      let(:database_name) { nil }
      let(:operation) { nil }

      it 'returns nil' do
        assert_nil(db_operation_and_name)
      end
    end
  end

  describe '.extract_statement_type' do
    let(:sql) { 'SELECT * FROM users' }
    let(:extract_statement_type) { OpenTelemetry::Helpers::MySQL.extract_statement_type(sql) }

    describe 'when it finds a match' do
      it 'returns the query name' do
        assert_equal('select', extract_statement_type)
      end
    end

    describe 'when sql contains invalid byte sequences' do
      let(:sql) { "SELECT * from users where users.id = 1 and users.email = 'test@test.com\255'" }

      it 'extracts the statement' do
        assert_equal('select', extract_statement_type)
      end
    end

    describe 'when sql contains unknown query statement' do
      let(:sql) { 'DESELECT 1' }

      # nil sets the span name to 'mysql'
      it 'returns nil' do
        assert_nil(extract_statement_type)
      end
    end

    describe 'when sql contains multiple query statements' do
      let(:sql) { 'EXPLAIN SELECT 1' }

      it 'extracts the statement type that begins the query' do
        assert_equal('explain', extract_statement_type)
      end
    end

    describe 'when sql with marginalia-style prepended comments includes a query statement' do
      let(:sql) do
        "/*action='update',application='TrilogyTest',controller='users'*/ SELECT `users`.* FROM `users` WHERE `users`.`id` = 1 LIMIT 1"
      end

      it 'does not capture the query statement within the comment' do
        assert_equal('select', extract_statement_type)
      end
    end

    describe 'when sql is nil' do
      let(:sql) { nil }

      it 'returns nil' do
        assert_nil(extract_statement_type)
      end
    end

    describe 'when an error is raised' do
      it 'logs a message' do
        result = nil
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::Common::Utilities.stub(:utf8_encode, ->(_) { raise 'boom!' }) do
            extract_statement_type

            assert_nil(result)
            assert_match(/Error extracting/, log_stream.string)
          end
        end
      end
    end
  end
end
