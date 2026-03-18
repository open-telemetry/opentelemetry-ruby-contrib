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

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
        _(span.attributes['db.namespace']).must_equal(database)
        _(span.attributes['db.query.text']).must_equal 'SELECT ?'
      end

      it 'includes server.port (stable) but not net.peer.port (was not in old)' do
        client.query('SELECT 1')

        _(span.attributes['server.port']).must_equal port
        _(span.attributes.key?('net.peer.port')).must_equal false
      end

      it 'extracts statement type' do
        explain_sql = 'EXPLAIN SELECT 1'
        client.query(explain_sql)

        _(span.name).must_equal 'explain'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'EXPLAIN SELECT ?'

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'EXPLAIN SELECT ?'
      end

      it 'uses component.name and instance.name as span.name fallbacks with invalid sql' do
        expect do
          client.query('DESELECT 1')
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'mysql'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'DESELECT ?'

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'DESELECT ?'
      end
    end

    describe 'when connecting' do
      let(:span) { exporter.finished_spans.first }

      it 'includes both old and stable attributes for connect span' do
        _(client.connected_host).wont_be_nil

        _(span.name).must_equal 'connect'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_USER]).must_equal(username)

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
        _(span.attributes['db.namespace']).must_equal(database)
      end
    end

    describe 'when pinging' do
      let(:span) { exporter.finished_spans[2] }

      it 'includes both old and stable attributes for ping span' do
        _(client.connected_host).wont_be_nil

        client.ping

        _(span.name).must_equal 'ping'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]).must_equal(host)
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_NAME]).must_equal(database)

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['server.address']).must_equal(host)
        _(span.attributes['db.namespace']).must_equal(database)
      end
    end

    describe 'when queries fail' do
      it 'sets span status to error' do
        expect do
          client.query('SELECT INVALID')
        end.must_raise Trilogy::Error

        _(span.name).must_equal 'select'

        # Old attributes
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]).must_equal 'mysql'
        _(span.attributes[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]).must_equal 'SELECT INVALID'

        # Stable attributes
        _(span.attributes['db.system.name']).must_equal 'mysql'
        _(span.attributes['db.query.text']).must_equal 'SELECT INVALID'

        _(span.status.code).must_equal(
          OpenTelemetry::Trace::Status::ERROR
        )
      end

      it 'sets error.type to the exception class name' do
        error = nil
        begin
          client.query('SELECT INVALID')
        rescue Trilogy::Error => e
          error = e
        end

        _(error).wont_be_nil
        _(span.attributes['error.type']).must_equal error.class.name
      end

      it 'sets db.response.status_code when error has error_code' do
        error = nil
        begin
          client.query('SELECT INVALID')
        rescue Trilogy::Error => e
          error = e
        end

        _(error).wont_be_nil
        if error.error_code
          _(span.attributes['db.response.status_code']).must_equal error.error_code.to_s
        end
      end

      describe 'when record_exception is true' do
        let(:config) { { record_exception: true } }

        it 'records the exception' do
          expect do
            client.query('SELECT INVALID')
          end.must_raise Trilogy::Error

          _(span.events).wont_be_nil
          _(span.events.first.name).must_equal 'exception'
          _(span.events.first.attributes['exception.type']).must_match(/Trilogy.*Error/)
          _(span.events.first.attributes['exception.message']).wont_be_nil
          _(span.events.first.attributes['exception.stacktrace']).wont_be_nil
        end
      end

      describe 'when record_exception is false' do
        let(:config) { { record_exception: false } }

        it 'does not record the exception' do
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

      it 'encodes invalid byte sequences' do
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
  end
end
