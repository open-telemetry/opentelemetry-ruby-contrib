# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy'
require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy/patches/stable/client'

# Unit tests for the stable semantic conventions client_attributes.
# We use Trilogy.allocate + manual ivar setup to test attribute building in isolation.
describe OpenTelemetry::Instrumentation::Trilogy::Patches::Stable::Client do
  # Helper to build a test client without a real MySQL connection.
  def build_test_client(options)
    c = Trilogy.allocate
    c.instance_variable_set(:@connection_options, options)
    c.instance_variable_set(:@_otel_database_name, options[:database])
    c.instance_variable_set(:@_otel_base_attributes, c.send(:_build_otel_base_attributes).freeze)
    c
  end

  let(:instrumentation) { OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  let(:connection_options) do
    {
      host: 'db-primary.example.com',
      port: 3307,
      database: 'myapp_production',
      username: 'app_user'
    }
  end

  let(:client) { build_test_client(connection_options) }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    exporter.reset
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install({
                              db_statement: :omit,
                              span_name: :statement_type,
                              propagator: 'none',
                              record_exception: true,
                              obfuscation_limit: 2000,
                              peer_service: nil
                            })
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#client_attributes' do
    it 'includes db.system.name as mysql' do
      attrs = client.send(:client_attributes)
      assert_equal 'mysql', attrs['db.system.name']
    end

    it 'includes server.address from host option' do
      attrs = client.send(:client_attributes)
      assert_equal 'db-primary.example.com', attrs['server.address']
    end

    it 'includes server.port when present' do
      attrs = client.send(:client_attributes)
      assert_equal 3307, attrs['server.port']
    end

    it 'includes server.port even when default (3306)' do
      c = build_test_client({ host: 'h', port: 3306 })
      attrs = c.send(:client_attributes)
      assert_equal 3306, attrs['server.port']
    end

    it 'includes db.namespace from database option' do
      attrs = client.send(:client_attributes)
      assert_equal 'myapp_production', attrs['db.namespace']
    end

    it 'falls back to unknown sock when host is nil' do
      c = build_test_client({ database: 'test' })
      attrs = c.send(:client_attributes)
      assert_equal 'unknown sock', attrs['server.address']
    end

    it 'omits db.namespace when database is nil' do
      c = build_test_client({ host: 'h' })
      attrs = c.send(:client_attributes)
      refute attrs.key?('db.namespace')
    end

    it 'includes peer_service when configured' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.instance_variable_set(:@semconv, :stable)
      instrumentation.install({
                                db_statement: :omit,
                                span_name: :statement_type,
                                propagator: 'none',
                                record_exception: true,
                                obfuscation_limit: 2000,
                                peer_service: 'mysql-primary'
                              })
      attrs = client.send(:client_attributes)
      assert_equal 'mysql-primary', attrs[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE]
    end

    it 'returns independent hash instances on each call' do
      a = client.send(:client_attributes)
      b = client.send(:client_attributes)
      refute_same a, b
      a['extra'] = 'value'
      refute b.key?('extra')
    end

    describe 'with sql and db_statement config' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.instance_variable_set(:@semconv, :stable)
      end

      it 'includes SQL as db.query.text when db_statement is :include' do
        instrumentation.install({
                                  db_statement: :include,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users')
        assert_equal 'SELECT * FROM users', attrs['db.query.text']
      end

      it 'omits db.query.text when db_statement is :omit' do
        instrumentation.install({
                                  db_statement: :omit,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users')
        refute attrs.key?('db.query.text')
      end

      it 'obfuscates SQL in db.query.text when db_statement is :obfuscate' do
        instrumentation.install({
                                  db_statement: :obfuscate,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users WHERE id = 1')
        stmt = attrs['db.query.text']
        assert stmt, 'expected db.query.text to be present'
        refute_includes stmt, '1'
      end
    end

    describe 'does not include old attributes' do
      it 'does not include db.system' do
        attrs = client.send(:client_attributes)
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM)
      end

      it 'does not include net.peer.name' do
        attrs = client.send(:client_attributes)
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME)
      end

      it 'does not include db.name' do
        attrs = client.send(:client_attributes)
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_NAME)
      end

      it 'does not include db.user (removed in stable)' do
        attrs = client.send(:client_attributes)
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_USER)
      end

      it 'does not include db.statement' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.instance_variable_set(:@semconv, :stable)
        instrumentation.install({
                                  db_statement: :include,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users')
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT)
      end
    end
  end
end
