# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy'
require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy/patches/dup/client'

describe 'OpenTelemetry::Instrumentation::Trilogy (dup semconv)' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans[1] }
  let(:config) { {} }
  let(:driver_options) do
    {
      host: host,
      port: port,
      username: username,
      password: password,
      database: database,
      ssl: false
    }
  end
  let(:client) do
    Trilogy.new(driver_options)
  end

  let(:host) { ENV.fetch('TEST_MYSQL_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_MYSQL_PORT', '3306').to_i }
  let(:database) { ENV.fetch('TEST_MYSQL_DB', 'mysql') }
  let(:username) { ENV.fetch('TEST_MYSQL_USER', 'root') }
  let(:password) { ENV.fetch('TEST_MYSQL_PASSWORD', 'root') }

  before do
    skip unless ENV['BUNDLE_GEMFILE']&.include?('dup')

    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Trilogy'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:mysql')
      client.query('SELECT 1')

      _(span.attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE]).must_equal 'readonly:mysql'
    end

    it 'omits peer service by default' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({})
      client.query('SELECT 1')

      _(span.attributes.keys).wont_include(OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE)
    end
  end

  describe '#compatible?' do
    describe 'when an unsupported version is installed' do
      it 'is incompatible' do
        stub_const('Trilogy::VERSION', '2.2.0')
        _(instrumentation.compatible?).must_equal false

        stub_const('Trilogy::VERSION', '2.3.0.beta')
        _(instrumentation.compatible?).must_equal false

        stub_const('Trilogy::VERSION', '3.0.0')
        _(instrumentation.compatible?).must_equal false
      end
    end

    describe 'when supported version is installed' do
      it 'is compatible' do
        stub_const('Trilogy::VERSION', '2.3.0')
        _(instrumentation.compatible?).must_equal true

        stub_const('Trilogy::VERSION', '3.0.0.rc1')
        _(instrumentation.compatible?).must_equal true
      end
    end
  end

  describe 'tracing' do
    before do
      instrumentation.install(config)
    end

    describe '.attributes' do
      let(:attributes) { { 'db.statement' => 'foobar' } }

      it 'returns an empty hash by default' do
        _(OpenTelemetry::Instrumentation::Trilogy.attributes).must_equal({})
      end

      it 'returns the current attributes hash' do
        OpenTelemetry::Instrumentation::Trilogy.with_attributes(attributes) do
          _(OpenTelemetry::Instrumentation::Trilogy.attributes).must_equal(attributes)
        end
      end

      it 'sets span attributes according to with_attributes hash' do
        OpenTelemetry::Instrumentation::Trilogy.with_attributes(attributes) do
          client.query('SELECT 1')
        end

        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'foobar'
      end
    end

    describe 'with default options' do
      it 'obfuscates sql in both old and stable attributes' do
        client.query('SELECT 1')

        _(span.name).must_equal 'select'
        # Old attribute
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        # Stable attribute
        _(span.attributes['db.query.text']).must_equal 'SELECT ?'
      end

      it 'includes both old and stable database connection information' do
        client.query('SELECT 1')

        _(span.name).must_equal 'select'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(span.attributes['db.instance.id']).must_be_nil

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
        _(span.attributes['server.port']).must_equal(port)
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.query.text']).must_equal 'SELECT ?'
      end

      it 'extracts operation name from SQL for span name' do
        explain_sql = 'EXPLAIN SELECT 1'
        client.query(explain_sql)

        _(span.name).must_equal 'explain'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'EXPLAIN SELECT ?'

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'EXPLAIN SELECT ?'
      end

      it 'uses component.name and instance.name as span.name fallbacks with invalid sql' do
        expect do
          client.query('DESELECT 1')
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'mysql'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'DESELECT ?'

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'DESELECT ?'
      end
    end

    describe 'when connecting' do
      let(:span) { exporter.finished_spans.first }

      it 'spans will include both old and stable database attributes' do
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'connect'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(span.attributes['db.instance.id']).must_be_nil

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
      end
    end

    describe 'when pinging' do
      let(:span) { exporter.finished_spans[2] }

      it 'spans will include both old and stable database attributes' do
        _(client.connected_host).wont_be_nil

        client.ping

        _(span.name).must_equal 'ping'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
      end
    end

    describe 'when quering for the connected host' do
      it 'spans will include both old and stable attributes' do
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'select'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'select @@hostname'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(span.attributes['db.instance.id']).must_be_nil

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'select @@hostname'
        _(span.attributes['server.address']).must_equal(host)

        client.query('SELECT 1')

        last_span = exporter.finished_spans.last

        _(last_span.name).must_equal 'select'

        # Old attributes on last span
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(last_span.attributes['db.instance.id']).must_equal client.connected_host

        # Stable attributes on last span
        _(last_span.attributes['db.namespace']).must_equal(database)
        _(last_span.attributes['db.system.name']).must_equal 'mysql'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT ?'
        _(last_span.attributes['server.address']).must_equal(host)
      end
    end

    describe 'when quering using unix domain socket' do
      let(:client) do
        Trilogy.new(
          username: username,
          password: password,
          ssl: false
        )
      end

      it 'spans will include both old and stable attributes' do
        skip 'requires setup of a mysql host using uds connections'
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'select'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'select @@hostname'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_match(/sock/)

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'select @@hostname'
        _(span.attributes['server.address']).must_match(/sock/)

        client.query('SELECT 1')

        last_span = exporter.finished_spans.last

        _(last_span.name).must_equal 'select'

        # Old attributes
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT ?'
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).wont_equal(/sock/)
        _(last_span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal client.connected_host

        # Stable attributes
        _(last_span.attributes['db.namespace']).must_equal(database)
        _(last_span.attributes['db.system.name']).must_equal 'mysql'
        _(last_span.attributes['db.query.text']).must_equal 'SELECT ?'
        _(last_span.attributes['server.address']).wont_equal(/sock/)
        _(last_span.attributes['server.address']).must_equal client.connected_host
      end
    end

    describe 'when queries fail' do
      it 'sets span status to error' do
        expect do
          client.query('SELECT INVALID')
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT INVALID'

        # Stable attributes
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'SELECT INVALID'

        _(span.status.code).must_equal(
          OpenTelemetry::Trace::Status::ERROR
        )
        _(span.events.first.name).must_equal 'exception'
        _(span.events.first.attributes['exception.type']).must_match(/Trilogy.*Error/)
        _(span.events.first.attributes['exception.message']).wont_be_nil
        _(span.events.first.attributes['exception.stacktrace']).wont_be_nil
      end

      it 'sets error.type to the exception class name' do
        expect do
          client.query('SELECT INVALID')
        end.must_raise Trilogy::Error

        _(span.attributes['error.type']).must_equal 'Trilogy::ProtocolError'
      end

      it 'sets db.response.status_code when error has error_code' do
        expect do
          client.query('SELECT INVALID')
        end.must_raise Trilogy::Error

        # 1054 is MySQL's "Unknown column" error code
        _(span.attributes['db.response.status_code']).must_equal '1054'
      end

      describe 'when record_exception is false' do
        let(:config) { { record_exception: false } }

        it 'does not record exception when record_exception is false' do
          expect do
            client.query('SELECT INVALID')
          end.must_raise Trilogy::Error

          _(span.events).must_be_nil
        end
      end
    end

    describe 'when db_statement is set to include' do
      let(:config) { { db_statement: :include } }

      it 'includes the db query statement in both attributes' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal sql
        _(span.attributes['db.query.text']).must_equal sql
      end
    end

    describe 'when db_statement is set to obfuscate' do
      let(:config) { { db_statement: :obfuscate } }

      it 'obfuscates SQL parameters in both attributes' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal obfuscated_sql
        _(span.attributes['db.query.text']).must_equal obfuscated_sql
      end

      it 'encodes invalid byte sequences for both attributes' do
        # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
        sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com\255'"
        obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'

        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal obfuscated_sql
        _(span.attributes['db.query.text']).must_equal obfuscated_sql
      end

      describe 'with obfuscation_limit' do
        let(:config) { { db_statement: :obfuscate, obfuscation_limit: 10 } }

        it 'returns a message when the limit is reached' do
          sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
          obfuscated_sql = 'SQL not obfuscated, query exceeds 10 characters'
          expect do
            client.query(sql)
          end.must_raise Trilogy::Error

          _(span.attributes['db.statement']).must_equal obfuscated_sql
          _(span.attributes['db.query.text']).must_equal obfuscated_sql
        end
      end
    end

    describe 'when propagator is set to none' do
      let(:config) { { propagator: :none } }

      it 'does not inject context' do
        sql = +'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        original_sql = sql.dup
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error
        _(sql).must_equal original_sql
      end
    end

    describe 'when propagator is set to nil' do
      let(:config) { { propagator: nil } }

      it 'does not inject context' do
        sql = +'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        original_sql = sql.dup
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error
        _(sql).must_equal original_sql
      end
    end

    describe 'when propagator is set to vitess' do
      let(:config) { { propagator: 'vitess' } }

      it 'does inject context on frozen strings' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        assert(sql.frozen?)
        propagator = OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance.propagator

        arg_cache = {} # maintain handles to args
        allow(client).to receive(:query).and_wrap_original do |m, *args|
          arg_cache[:query_input] = args[0]
          assert(args[0].frozen?)
          m.call(args[0])
        end

        allow(propagator).to receive(:inject).and_wrap_original do |m, *args|
          arg_cache[:inject_input] = args[0]
          refute(args[0].frozen?)
          assert_match(sql, args[0])
          m.call(args[0], context: args[1][:context])
        end

        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        # arg_cache[:inject_input] _was_ a mutable string, so it has the context injected
        encoded = Base64.strict_encode64("{\"uber-trace-id\":\"#{span.hex_trace_id}:#{span.hex_span_id}:0:1\"}")
        assert_equal(arg_cache[:inject_input], "/*VT_SPAN_CONTEXT=#{encoded}*/#{sql}")

        # arg_cache[:inject_input] is now frozen
        assert(arg_cache[:inject_input].frozen?)
      end

      it 'does inject context on unfrozen strings' do
        # inbound SQL is not frozen (string prefixed with +)
        sql = +'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        refute(sql.frozen?)

        # dup sql for comparison purposes, since propagator  mutates it
        cached_sql = sql.dup

        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        encoded = Base64.strict_encode64("{\"uber-trace-id\":\"#{span.hex_trace_id}:#{span.hex_span_id}:0:1\"}")
        assert_equal(sql, "/*VT_SPAN_CONTEXT=#{encoded}*/#{cached_sql}")
        refute(sql.frozen?)
      end
    end

    describe 'when propagator is set to tracecontext' do
      let(:config) { { propagator: 'tracecontext' } }

      it 'injects context on frozen strings' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        _(sql).must_be :frozen?
        propagator = OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance.propagator

        arg_cache = {} # maintain handles to args
        allow(client).to receive(:query).and_wrap_original do |m, *args|
          arg_cache[:query_input] = args[0]
          _(args[0]).must_be :frozen?
          m.call(args[0])
        end

        allow(propagator).to receive(:inject).and_wrap_original do |m, *args|
          arg_cache[:inject_input] = args[0]
          _(args[0]).wont_be :frozen?
          _(args[0]).must_match(sql)
          m.call(args[0], context: args[1][:context])
        end

        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        # arg_cache[:inject_input] _was_ a mutable string, so it has the context injected
        # The tracecontext propagator injects traceparent and tracestate headers as SQL comments
        _(arg_cache[:inject_input]).must_match(%r{/\*traceparent='00-#{span.hex_trace_id}-#{span.hex_span_id}-01'\*/})

        # arg_cache[:inject_input] is now frozen
        _(arg_cache[:inject_input]).must_be :frozen?
      end

      it 'injects context on unfrozen strings' do
        # inbound SQL is not frozen (string prefixed with +)
        sql = +'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        _(sql).wont_be :frozen?

        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        # The tracecontext propagator injects traceparent header as SQL comment
        _(sql).must_match(%r{/\*traceparent='00-#{span.hex_trace_id}-#{span.hex_span_id}-01'\*/})
        _(sql).wont_be :frozen?
      end
    end

    describe 'when db_statement is set to omit' do
      let(:config) { { db_statement: :omit } }

      it 'does not include SQL statement in either attribute' do
        sql = 'SELECT * from users where users.id = 1 and users.email = "test@test.com"'
        expect do
          client.query(sql)
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_be_nil
        _(span.attributes['db.query.text']).must_be_nil
      end
    end

    describe 'when db_statement is configured via environment variable' do
      describe 'when db_statement set as omit' do
        it 'omits both db.statement and db.query.text attributes' do
          OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_INSTRUMENTATION_TRILOGY_CONFIG_OPTS' => 'db_statement=omit;') do
            instrumentation.instance_variable_set(:@installed, false)
            instrumentation.install
            sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
            expect do
              client.query(sql)
            end.must_raise Trilogy::Error

            _(span.attributes['db.system']).must_equal 'mysql'
            _(span.attributes['db.system.name']).must_equal 'mysql'
            _(span.name).must_equal 'select'
            _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_be_nil
            _(span.attributes['db.query.text']).must_be_nil
          end
        end
      end

      describe 'when db_statement set as obfuscate' do
        it 'obfuscates SQL parameters in both attributes' do
          OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_INSTRUMENTATION_TRILOGY_CONFIG_OPTS' => 'db_statement=obfuscate;') do
            instrumentation.instance_variable_set(:@installed, false)
            instrumentation.install

            sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
            obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
            expect do
              client.query(sql)
            end.must_raise Trilogy::Error

            _(span.attributes['db.system']).must_equal 'mysql'
            _(span.attributes['db.system.name']).must_equal 'mysql'
            _(span.name).must_equal 'select'
            _(span.attributes['db.statement']).must_equal obfuscated_sql
            _(span.attributes['db.query.text']).must_equal obfuscated_sql
          end
        end
      end

      describe 'when db_statement is set differently than local config' do
        let(:config) { { db_statement: :omit } }

        it 'overrides local config and obfuscates SQL parameters in both attributes' do
          OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_INSTRUMENTATION_TRILOGY_CONFIG_OPTS' => 'db_statement=obfuscate') do
            instrumentation.instance_variable_set(:@installed, false)
            instrumentation.install

            sql = "SELECT * from users where users.id = 1 and users.email = 'test@test.com'"
            obfuscated_sql = 'SELECT * from users where users.id = ? and users.email = ?'
            expect do
              client.query(sql)
            end.must_raise Trilogy::Error

            _(span.attributes['db.system']).must_equal 'mysql'
            _(span.attributes['db.system.name']).must_equal 'mysql'
            _(span.name).must_equal 'select'
            _(span.attributes['db.statement']).must_equal obfuscated_sql
            _(span.attributes['db.query.text']).must_equal obfuscated_sql
          end
        end
      end
    end

  end
end
