# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'active_record'
require 'pg'

require_relative '../../../../../lib/opentelemetry/instrumentation/pg'
require_relative '../../../../../lib/opentelemetry/instrumentation/pg/patches/stable/connection'

# This test suite requires a running postgres container and dedicated test container
# To run tests locally:
# 1. Build the opentelemetry/opentelemetry-ruby-contrib image
# - docker-compose build
# 2. Bundle install
# - docker-compose run ex-instrumentation-pg-test bundle exec appraisal install
# 3. Run test suite with Appraisal
# - docker-compose run ex-instrumentation-pg-test bundle exec appraisal rake test

describe OpenTelemetry::Instrumentation::PG::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::PG::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }
  let(:config) { {} }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database'

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

    describe 'connection initialization' do
      it 'creates a connect span when establishing a connection' do
        conn = PG::Connection.open(
          host: host,
          port: port,
          user: user,
          dbname: dbname,
          password: password
        )
        conn.close

        _(exporter.finished_spans.size).must_equal 1
        connect_span = exporter.finished_spans.first
        _(connect_span.name).must_equal 'connect'
        _(connect_span.kind).must_equal :client
        _(connect_span.attributes['db.system.name']).must_equal 'postgresql'
        _(connect_span.attributes['db.namespace']).must_equal dbname
        _(connect_span.attributes['server.address']).must_equal host
        # Should NOT have old conventions
        _(connect_span.attributes['db.system']).must_be_nil
        _(connect_span.attributes['db.name']).must_be_nil
        _(connect_span.attributes['db.user']).must_be_nil
        _(connect_span.attributes['net.peer.name']).must_be_nil
        _(connect_span.attributes['net.transport']).must_be_nil
      end

      it 'creates a connect span using PG::Connection.new' do
        conn = PG::Connection.new(
          host: host,
          port: port,
          user: user,
          dbname: dbname,
          password: password
        )
        conn.close

        connect_span = exporter.finished_spans.first
        _(connect_span.name).must_equal 'connect'
        _(connect_span.kind).must_equal :client
        _(connect_span.attributes['db.system.name']).must_equal 'postgresql'
        _(connect_span.attributes['db.namespace']).must_equal dbname
      end

      it 'creates a connect span using PG.connect' do
        conn = PG.connect(
          host: host,
          port: port,
          user: user,
          dbname: dbname,
          password: password
        )
        conn.close

        connect_span = exporter.finished_spans.first
        _(connect_span.name).must_equal 'connect'
        _(connect_span.kind).must_equal :client
        _(connect_span.attributes['db.system.name']).must_equal 'postgresql'
      end

      it 'accepts peer service name from config for connection' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(peer_service: 'readonly:postgres')

        conn = PG::Connection.open(
          host: host,
          port: port,
          user: user,
          dbname: dbname,
          password: password
        )
        conn.close

        connect_span = exporter.finished_spans.first
        _(connect_span.attributes['peer.service']).must_equal 'readonly:postgres'
      end

      it 'records connection errors with error.type' do
        expect do
          PG::Connection.open(
            host: host,
            port: port,
            user: 'invalid_user',
            dbname: dbname,
            password: 'wrong_password'
          )
        end.must_raise PG::ConnectionBad

        connect_span = exporter.finished_spans.first
        _(connect_span.name).must_equal 'connect'
        _(connect_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(connect_span.attributes['error.type']).must_equal 'PG::ConnectionBad'
        _(connect_span.events.first.name).must_equal 'exception'
        _(connect_span.events.first.attributes['exception.type']).must_equal 'PG::ConnectionBad'
      end
    end

    describe 'server.port attribute' do
      it 'does not include server.port when using default port (5432)' do
        client.query('SELECT 1')

        _(last_span.attributes['server.port']).must_be_nil
      end
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:postgres')
      client.query('SELECT 1')

      _(last_span.attributes['peer.service']).must_equal 'readonly:postgres'
    end

    describe '.attributes' do
      let(:attributes) do
        {
          'db.namespace' => 'pg',
          'db.query.text' => 'foobar',
          'db.operation.name' => 'PREPARE FOR SELECT 1',
          'db.postgresql.prepared_statement_name' => 'bar',
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

        _(last_span.attributes['db.namespace']).must_equal 'pg'
        _(last_span.attributes['db.query.text']).must_equal 'foobar'
        _(last_span.attributes['db.operation.name']).must_equal 'PREPARE FOR SELECT 1'
        _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'bar'
        _(last_span.attributes['peer.service']).must_equal 'example:custom'
      end
    end

    %i[exec query sync_exec async_exec].each do |method|
      it "after request (with method: #{method})" do
        client.send(method, 'SELECT 1')

        _(last_span.name).must_equal 'SELECT postgres'
        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT 1'
        _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
        _(last_span.attributes['server.address']).must_equal host.to_s
        # Should NOT have old conventions
        _(last_span.attributes['db.system']).must_be_nil
        _(last_span.attributes['db.name']).must_be_nil
        _(last_span.attributes['db.statement']).must_be_nil
        _(last_span.attributes['db.operation']).must_be_nil
        _(last_span.attributes['net.peer.name']).must_be_nil
      end
    end

    %i[exec_params async_exec_params sync_exec_params].each do |method|
      it "after request (with method: #{method}) " do
        client.send(method, 'SELECT $1 AS a', [1])

        _(last_span.name).must_equal 'SELECT postgres'
        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT $1 AS a'
        _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
        _(last_span.attributes['server.address']).must_equal host.to_s
      end
    end

    %i[prepare async_prepare sync_prepare].each do |method|
      it "after preparing a statement (with method: #{method})" do
        client.send(method, 'foo', 'SELECT $1 AS a')

        _(last_span.name).must_equal 'PREPARE postgres'
        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT $1 AS a'
        _(last_span.attributes['db.operation.name']).must_equal 'PREPARE'
        _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo'
        _(last_span.attributes['server.address']).must_equal host.to_s
      end
    end

    %i[exec_prepared async_exec_prepared sync_exec_prepared].each do |method|
      it "after executing prepared statement (with method: #{method})" do
        client.prepare('foo', 'SELECT $1 AS a')
        client.send(method, 'foo', [1])

        _(last_span.name).must_equal 'EXECUTE postgres'
        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.attributes['db.operation.name']).must_equal 'EXECUTE'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT $1 AS a'
        _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo'
        _(last_span.attributes['server.address']).must_equal host.to_s
      end
    end

    %i[exec query sync_exec async_exec].each do |method|
      it "after request using Arel (with method: #{method})" do
        client.send(method, Arel.sql('SELECT 1'))

        _(last_span.name).must_equal 'SELECT postgres'
        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT 1'
        _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
        _(last_span.attributes['server.address']).must_equal host.to_s
      end
    end

    it 'ignores prepend comment to extract operation' do
      client.query('/* comment */ SELECT 1')

      _(last_span.name).must_equal 'SELECT postgres'
      _(last_span.attributes['db.system.name']).must_equal 'postgresql'
      _(last_span.attributes['db.namespace']).must_equal 'postgres'
      _(last_span.attributes['db.query.text']).must_equal '/* comment */ SELECT 1'
      _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
      _(last_span.attributes['server.address']).must_equal host.to_s
    end

    it 'only caches 50 prepared statement names' do
      51.times { |i| client.prepare("foo#{i}", "SELECT $1 AS foo#{i}") }
      client.exec_prepared('foo0', [1])

      _(last_span.name).must_equal 'EXECUTE postgres'
      _(last_span.attributes['db.system.name']).must_equal 'postgresql'
      _(last_span.attributes['db.namespace']).must_equal 'postgres'
      _(last_span.attributes['db.operation.name']).must_equal 'EXECUTE'
      # We should have evicted the statement from the cache
      _(last_span.attributes['db.query.text']).must_be_nil
      _(last_span.attributes['db.postgresql.prepared_statement_name']).must_equal 'foo0'
      _(last_span.attributes['server.address']).must_equal host.to_s
    end

    it 'after error sets error.type attribute' do
      expect do
        client.exec('SELECT INVALID')
      end.must_raise PG::UndefinedColumn

      _(last_span.name).must_equal 'SELECT postgres'
      _(last_span.attributes['db.system.name']).must_equal 'postgresql'
      _(last_span.attributes['db.namespace']).must_equal 'postgres'
      _(last_span.attributes['db.query.text']).must_equal 'SELECT INVALID'
      _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
      _(last_span.attributes['server.address']).must_equal host.to_s

      # Stable convention error handling
      _(last_span.attributes['error.type']).must_equal 'PG::UndefinedColumn'

      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(last_span.events.first.name).must_equal 'exception'
      _(last_span.events.first.attributes['exception.type']).must_equal 'PG::UndefinedColumn'
      assert(!last_span.events.first.attributes['exception.message'].nil?)
      assert(!last_span.events.first.attributes['exception.stacktrace'].nil?)
    end

    it 'extracts statement type that begins the query' do
      base_sql = 'SELECT 1'
      explain = 'EXPLAIN'
      explain_sql = "#{explain} #{base_sql}"
      client.exec(explain_sql)

      _(last_span.name).must_equal 'EXPLAIN postgres'
      _(last_span.attributes['db.system.name']).must_equal 'postgresql'
      _(last_span.attributes['db.namespace']).must_equal 'postgres'
      _(last_span.attributes['db.query.text']).must_equal explain_sql
      _(last_span.attributes['db.operation.name']).must_equal 'EXPLAIN'
      _(last_span.attributes['server.address']).must_equal host.to_s
    end

    it 'uses database name as span.name fallback with invalid sql' do
      expect do
        client.exec('DESELECT 1')
      end.must_raise PG::SyntaxError

      _(last_span.name).must_equal 'postgres'
      _(last_span.attributes['db.system.name']).must_equal 'postgresql'
      _(last_span.attributes['db.namespace']).must_equal 'postgres'
      _(last_span.attributes['db.query.text']).must_equal 'DESELECT 1'
      _(last_span.attributes['db.operation.name']).must_be_nil
      _(last_span.attributes['server.address']).must_equal host.to_s
      _(last_span.attributes['error.type']).must_equal 'PG::SyntaxError'

      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(last_span.events.first.name).must_equal 'exception'
      _(last_span.events.first.attributes['exception.type']).must_equal 'PG::SyntaxError'
      assert(!last_span.events.first.attributes['exception.message'].nil?)
      assert(!last_span.events.first.attributes['exception.stacktrace'].nil?)
    end

    it 'extracts table name' do
      client.query('CREATE TABLE test_table (personid int, name VARCHAR(50))')

      _(last_span.attributes['db.collection.name']).must_equal 'test_table'
      client.query('DROP TABLE test_table') # Drop table to avoid conflicts
    end

    describe 'when propagator is set to tracecontext' do
      let(:config) { { propagator: 'tracecontext' } }

      it 'injects context into SQL query' do
        sql = +'SELECT * from users where users.id = 1'

        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        # Verify the SQL was modified with trace context
        _(sql).must_match(%r{/\*traceparent='00-#{last_span.hex_trace_id}-#{last_span.hex_span_id}-01'\*/})
      end

      it 'does not modify frozen strings' do
        sql = 'SELECT * from users where users.id = 1'
        _(sql).must_be :frozen?

        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        # Frozen strings should not be modified
        _(sql).wont_match(%r{/\*traceparent=})
      end
    end

    describe 'when propagator is set to none' do
      let(:config) { { propagator: 'none' } }

      it 'does not inject context' do
        sql = +'SELECT * from users where users.id = 1'
        original_sql = sql.dup

        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        _(sql).must_equal original_sql
      end
    end

    describe 'when db_statement is obfuscate' do
      let(:config) { { db_statement: :obfuscate } }

      it 'obfuscates SQL parameters in db.query.text' do
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
        obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.name).must_equal 'SELECT postgres'
        _(last_span.attributes['db.query.text']).must_equal obfuscated_sql
        _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
        _(last_span.attributes['server.address']).must_equal host.to_s
      end

      describe 'with obfuscation_limit' do
        let(:config) { { db_statement: :obfuscate, obfuscation_limit: 10 } }

        it 'returns a message when the limit is reached' do
          sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
          obfuscated_sql = 'SQL not obfuscated, query exceeds 10 characters'
          expect do
            client.exec(sql)
          end.must_raise PG::UndefinedTable

          _(last_span.attributes['db.query.text']).must_equal obfuscated_sql
        end
      end
    end

    describe 'when db_statement is omit' do
      let(:config) { { db_statement: :omit } }

      it 'does not include SQL statement as db.query.text attribute' do
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
        expect do
          client.exec(sql)
        end.must_raise PG::UndefinedTable

        _(last_span.attributes['db.system.name']).must_equal 'postgresql'
        _(last_span.attributes['db.namespace']).must_equal 'postgres'
        _(last_span.name).must_equal 'SELECT postgres'
        _(last_span.attributes['db.operation.name']).must_equal 'SELECT'
        _(last_span.attributes['server.address']).must_equal host.to_s

        _(last_span.attributes['db.query.text']).must_be_nil
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
