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

    describe 'recognizes all supported query names' do
      {
        'SELECT 1' => 'select',
        'INSERT INTO users VALUES (1)' => 'insert',
        'UPDATE users SET name = "a"' => 'update',
        'DELETE FROM users' => 'delete',
        'BEGIN' => 'begin',
        'COMMIT' => 'commit',
        'ROLLBACK' => 'rollback',
        'SAVEPOINT sp1' => 'savepoint',
        'RELEASE SAVEPOINT sp1' => 'release savepoint',
        'EXPLAIN SELECT 1' => 'explain',
        'DROP DATABASE test_db' => 'drop database',
        'DROP TABLE users' => 'drop table',
        'CREATE DATABASE test_db' => 'create database',
        'CREATE TABLE users (id INT)' => 'create table',
        "SET NAMES 'utf8mb4'" => 'set names'
      }.each do |query, expected|
        it "extracts '#{expected}' from: #{query[0..40]}" do
          assert_equal(expected, OpenTelemetry::Helpers::MySQL.extract_statement_type(query))
        end
      end
    end

    describe 'case insensitivity' do
      it 'handles uppercase' do
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type('SELECT 1'))
      end

      it 'handles lowercase' do
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type('select 1'))
      end

      it 'handles mixed case' do
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type('SeLeCt 1'))
      end

      it 'handles mixed case for multi-word keywords' do
        assert_equal('drop table', OpenTelemetry::Helpers::MySQL.extract_statement_type('Drop Table users'))
      end
    end

    describe 'leading whitespace' do
      it 'handles leading spaces' do
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type('   SELECT 1'))
      end

      it 'handles leading newlines' do
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type("\nSELECT 1"))
      end
    end

    describe 'queries with long trailing content' do
      it 'extracts from queries with large IN clauses' do
        ids = (1..500).to_a.join(', ')
        sql = "SELECT * FROM users WHERE id IN (#{ids})"
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'extracts from queries with multiple JOINs' do
        sql = <<~SQL
          SELECT u.*, p.*, c.*, o.*
          FROM users u
          JOIN profiles p ON p.user_id = u.id
          JOIN companies c ON c.id = u.company_id
          JOIN orders o ON o.user_id = u.id
          WHERE u.active = 1
        SQL
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'extracts from long INSERT with many values' do
        values = (1..100).map { |i| "(#{i}, 'user#{i}')" }.join(', ')
        sql = "INSERT INTO users (id, name) VALUES #{values}"
        assert_equal('insert', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end
    end

    describe 'prepended comments' do
      it 'handles marginalia-style comments' do
        sql = "/*action='update',application='TrilogyTest',controller='users'*/ SELECT `users`.* FROM `users` WHERE `users`.`id` = 1 LIMIT 1"
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'does not capture a keyword that appears only inside a comment' do
        sql = "/*action='delete'*/ SELECT 1"
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles comments with whitespace before and after' do
        sql = '  /* comment */  SELECT 1'
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles multi-line comments' do
        sql = "/* multi\nline\ncomment */ SELECT 1"
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end
    end

    describe 'encoding handling' do
      it 'handles UTF-8 encoded strings' do
        sql = (+'SELECT * FROM users').force_encoding('UTF-8')
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles ASCII encoded strings' do
        sql = (+'SELECT * FROM users').force_encoding('ASCII')
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles binary (ASCII-8BIT) encoded strings' do
        sql = (+'SELECT * FROM users').force_encoding('ASCII-8BIT')
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles strings with invalid byte sequences' do
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com\255'"
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end

      it 'handles frozen strings' do
        sql = 'SELECT * FROM users'
        assert_equal('select', OpenTelemetry::Helpers::MySQL.extract_statement_type(sql))
      end
    end

    describe 'nil and empty inputs' do
      it 'returns nil for nil' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type(nil))
      end

      it 'returns nil for empty string' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type(''))
      end

      it 'returns nil for whitespace-only string' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type('   '))
      end
    end

    describe 'unrecognized statements' do
      it 'returns nil for unknown keywords' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type('DESELECT 1'))
      end

      it 'returns nil for partial keyword matches' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type('SELECTIONS 1'))
      end

      it 'does not match keywords embedded mid-string' do
        assert_nil(OpenTelemetry::Helpers::MySQL.extract_statement_type('MYSELECT 1'))
      end
    end

    describe 'when an error is raised' do
      it 'logs a message' do
        sql = (+'SELECT 1').force_encoding('ASCII-8BIT')
        result = nil
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::Common::Utilities.stub(:utf8_encode, ->(_) { raise 'boom!' }) do
            result = OpenTelemetry::Helpers::MySQL.extract_statement_type(sql)

            assert_nil(result)
            assert_match(/Error extracting/, log_stream.string)
          end
        end
      end
    end
  end
end
