# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'active_record'
require 'pg'

require_relative '../../../../lib/opentelemetry/instrumentation/pg'
require_relative '../../../../lib/opentelemetry/instrumentation/pg/patches/connection'

# This test suite requires a running postgres container and dedicated test container
# To run tests locally:
# 1. Build the opentelemetry/opentelemetry-ruby-contrib image
# - docker-compose build
# 2. Bundle install
# - docker-compose run ex-instrumentation-pg-test bundle install
# 3. Install the dependencies for each Appraisal (https://github.com/thoughtbot/appraisal)
# - docker-compose run ex-instrumentation-pg-test bundle exec appraisal install
# 4. Run test suite with Appraisal
# - docker-compose run ex-instrumentation-pg-test bundle exec appraisal rake test

describe OpenTelemetry::Instrumentation::PG::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::PG::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }
  let(:config) { {} }

  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
    client&.close
  end

  describe 'tracing' do
    let(:client) do
      PG::Connection.open(
        host: host,
        port: port,
        user: user,
        dbname: dbname,
        password: password
      )
    end

    let(:host) { ENV.fetch('TEST_POSTGRES_HOST', '127.0.0.1') }
    let(:port) { ENV.fetch('TEST_POSTGRES_PORT', '5432') }
    let(:user) { ENV.fetch('TEST_POSTGRES_USER', 'postgres') }
    let(:dbname) { ENV.fetch('TEST_POSTGRES_DB', 'postgres') }
    let(:password) { ENV.fetch('TEST_POSTGRES_PASSWORD', 'postgres') }
    let(:config) { { db_statement: :include } }
    before do
      instrumentation.install(config)
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:postgres')
      client.query('SELECT 1')

      _(span.attributes['peer.service']).must_equal 'readonly:postgres'
    end

    describe '.attributes' do
      let(:attributes) do
        {
          'db.name' => 'pg',
          'db.statement' => 'foobar',
          'db.operation' => 'PREPARE FOR SELECT 1',
          'db.postgresql.prepared_statement_name' => 'bar',
          'net.peer.ip' => '192.168.0.1',
          'peer.service' => 'example:custom',
          'db.collection.name' => 'test_table'
        }
      end

      it 'returns an empty hash by default' do
        _(OpenTelemetry::Instrumentation::PG.attributes).must_equal({})
      end

      it 'returns the current attributes hash' do
        OpenTelemetry::Instrumentation::PG.with_attributes(attributes) do
          _(OpenTelemetry::Instrumentation::PG.attributes).must_equal(attributes)
        end
      end

      it 'sets span attributes according to with_attributes hash' do
        OpenTelemetry::Instrumentation::PG.with_attributes(attributes) do
          client.prepare('foo', 'SELECT 1')
        end

        _(span.attributes['db.name']).must_equal 'pg'
        _(span.attributes['db.statement']).must_equal 'foobar'
        _(span.attributes['db.operation']).must_equal 'PREPARE FOR SELECT 1'
        _(span.attributes['db.postgresql.prepared_statement_name']).must_equal 'bar'
        _(span.attributes['net.peer.ip']).must_equal '192.168.0.1'
        _(span.attributes['peer.service']).must_equal 'example:custom'
      end
    end

    %i[exec query sync_exec async_exec].each do |method|
      it "after request (with method: #{method})" do
        client.send(method, 'SELECT 1')

        _(span.name).must_equal 'SELECT postgres'
        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.attributes['db.statement']).must_equal 'SELECT 1'
        _(span.attributes['db.operation']).must_equal 'SELECT'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i
      end
    end

    %i[exec_params async_exec_params sync_exec_params].each do |method|
      it "after request (with method: #{method}) " do
        client.send(method, 'SELECT $1 AS a', [1])

        _(span.name).must_equal 'SELECT postgres'
        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.attributes['db.statement']).must_equal 'SELECT $1 AS a'
        _(span.attributes['db.operation']).must_equal 'SELECT'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i
      end
    end

    %i[prepare async_prepare sync_prepare].each do |method|
      it "after preparing a statement (with method: #{method})" do
        client.send(method, 'foo', 'SELECT $1 AS a')

        _(span.name).must_equal 'PREPARE postgres'
        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.attributes['db.statement']).must_equal 'SELECT $1 AS a'
        _(span.attributes['db.operation']).must_equal 'PREPARE'
        _(span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i
      end
    end

    %i[exec_prepared async_exec_prepared sync_exec_prepared].each do |method|
      it "after executing prepared statement (with method: #{method})" do
        client.prepare('foo', 'SELECT $1 AS a')
        client.send(method, 'foo', [1])

        _(last_span.name).must_equal 'EXECUTE postgres'
        _(last_span.attributes['db.system']).must_equal 'postgresql'
        _(last_span.attributes['db.name']).must_equal 'postgres'
        _(last_span.attributes['db.operation']).must_equal 'EXECUTE'
        _(last_span.attributes['db.statement']).must_equal 'SELECT $1 AS a'
        _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo'
        _(last_span.attributes['net.peer.name']).must_equal host.to_s
        _(last_span.attributes['net.peer.port']).must_equal port.to_i
      end
    end

    %i[exec query sync_exec async_exec].each do |method|
      it "after request using Arel (with method: #{method})" do
        client.send(method, Arel.sql('SELECT 1'))

        _(span.name).must_equal 'SELECT postgres'
        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.attributes['db.statement']).must_equal 'SELECT 1'
        _(span.attributes['db.operation']).must_equal 'SELECT'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i
      end
    end

    it 'ignores prepend comment to extract operation' do
      client.query('/* comment */ SELECT 1')

      _(span.name).must_equal 'SELECT postgres'
      _(span.attributes['db.system']).must_equal 'postgresql'
      _(span.attributes['db.name']).must_equal 'postgres'
      _(span.attributes['db.statement']).must_equal '/* comment */ SELECT 1'
      _(span.attributes['db.operation']).must_equal 'SELECT'
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_i
    end

    it 'only caches 50 prepared statement names' do
      51.times { |i| client.prepare("foo#{i}", "SELECT $1 AS foo#{i}") }
      client.exec_prepared('foo0', [1])

      _(last_span.name).must_equal 'EXECUTE postgres'
      _(last_span.attributes['db.system']).must_equal 'postgresql'
      _(last_span.attributes['db.name']).must_equal 'postgres'
      _(last_span.attributes['db.operation']).must_equal 'EXECUTE'
      # We should have evicted the statement from the cache
      _(last_span.attributes['db.statement']).must_be_nil
      _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo0'
      _(last_span.attributes['net.peer.name']).must_equal host.to_s
      _(last_span.attributes['net.peer.port']).must_equal port.to_i
    end

    it 'after error' do
      expect do
        client.exec('SELECT INVALID')
      end.must_raise PG::UndefinedColumn

      _(span.name).must_equal 'SELECT postgres'
      _(span.attributes['db.system']).must_equal 'postgresql'
      _(span.attributes['db.name']).must_equal 'postgres'
      _(span.attributes['db.statement']).must_equal 'SELECT INVALID'
      _(span.attributes['db.operation']).must_equal 'SELECT'
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_i

      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.events.first.name).must_equal 'exception'
      _(span.events.first.attributes['exception.type']).must_equal 'PG::UndefinedColumn'
      assert(!span.events.first.attributes['exception.message'].nil?)
      assert(!span.events.first.attributes['exception.stacktrace'].nil?)
    end

    it 'extracts statement type that begins the query' do
      base_sql = 'SELECT 1'
      explain = 'EXPLAIN'
      explain_sql = "#{explain} #{base_sql}"
      client.exec(explain_sql)

      _(span.name).must_equal 'EXPLAIN postgres'
      _(span.attributes['db.system']).must_equal 'postgresql'
      _(span.attributes['db.name']).must_equal 'postgres'
      _(span.attributes['db.statement']).must_equal explain_sql
      _(span.attributes['db.operation']).must_equal 'EXPLAIN'
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_i
    end

    it 'uses database name as span.name fallback with invalid sql' do
      expect do
        client.exec('DESELECT 1')
      end.must_raise PG::SyntaxError

      _(span.name).must_equal 'postgres'
      _(span.attributes['db.system']).must_equal 'postgresql'
      _(span.attributes['db.name']).must_equal 'postgres'
      _(span.attributes['db.statement']).must_equal 'DESELECT 1'
      _(span.attributes['db.operation']).must_be_nil
      _(span.attributes['net.peer.name']).must_equal host.to_s
      _(span.attributes['net.peer.port']).must_equal port.to_i

      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.events.first.name).must_equal 'exception'
      _(span.events.first.attributes['exception.type']).must_equal 'PG::SyntaxError'
      assert(!span.events.first.attributes['exception.message'].nil?)
      assert(!span.events.first.attributes['exception.stacktrace'].nil?)
    end

    it 'extracts table name' do
      client.query('CREATE TABLE test_table (personid int, name VARCHAR(50))')

      _(span.attributes['db.collection.name']).must_equal 'test_table'
      client.query('DROP TABLE test_table') # Drop table to avoid conflicts
    end

    describe 'when db_statement is obfuscate' do
      let(:config) { { db_statement: :obfuscate } }

      it 'obfuscates SQL parameters in db.statement' do
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
        obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.name).must_equal 'SELECT postgres'
        _(span.attributes['db.statement']).must_equal obfuscated_sql
        _(span.attributes['db.operation']).must_equal 'SELECT'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i
      end

      describe 'with obfuscation_limit' do
        let(:config) { { db_statement: :obfuscate, obfuscation_limit: 10 } }

        it 'returns a message when the limit is reached' do
          sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
          obfuscated_sql = 'SQL not obfuscated, query exceeds 10 characters'
          expect do
            client.exec(sql)
          end.must_raise PG::UndefinedTable

          _(span.attributes['db.statement']).must_equal obfuscated_sql
        end
      end
    end

    describe 'when db_statement is omit' do
      let(:config) { { db_statement: :omit } }

      it 'does not include SQL statement as db.statement attribute' do
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        _(span.attributes['db.system']).must_equal 'postgresql'
        _(span.attributes['db.name']).must_equal 'postgres'
        _(span.name).must_equal 'SELECT postgres'
        _(span.attributes['db.operation']).must_equal 'SELECT'
        _(span.attributes['net.peer.name']).must_equal host.to_s
        _(span.attributes['net.peer.port']).must_equal port.to_i

        _(span.attributes['db.statement']).must_be_nil
      end
    end

    describe 'when using a database socket' do
      let(:host) { nil }
      let(:port) { nil }

      it 'sets attributes for the socket directory and family' do
        client.query('SELECT 1')

        _(span.attributes['net.peer.name']).must_match %r{^/}
        _(span.attributes['net.peer.port']).must_be_nil
        _(span.attributes['net.sock.family']).must_equal 'unix'
      end
    end

    describe 'when connection has multiple hosts' do
      before { skip 'requires libpq >= 10.0' if PG.library_version < 10_00_00 } # rubocop:disable Style/NumericLiterals

      let(:client) do
        PG::Connection.open(
          host: ['nowhere.', host].join(','),
          port: ['20823', port].join(','),
          user: user,
          dbname: dbname,
          password: password
        )
      end

      it 'sets attributes of the active connection' do
        client.query('SELECT 1')

        _(span.attributes['net.peer.name']).must_equal host
        _(span.attributes['net.peer.port']).must_equal port.to_i if PG.const_defined?(:DEF_PORT)
      end
    end

    describe '#connection_name' do
      def self.load_fixture
        data = File.read("#{Dir.pwd}/test/fixtures/sql_table_name.json")
        JSON.parse(data)
      end

      load_fixture.each do |test_case|
        name = test_case['name']
        query = test_case['sql']

        it "returns the table name for #{name}" do
          table_name = client.send(:collection_name, query)

          expect(table_name).must_equal('test_table')
        end
      end
    end
  end unless ENV['OMIT_SERVICES']
end
