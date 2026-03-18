# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy'
require_relative '../../../../../../lib/opentelemetry/instrumentation/trilogy/patches/old/client'

# Unit tests for the client_attributes hot path that do not require
# a MySQL connection.  We use Trilogy.allocate + manual ivar setup
# to test attribute building in isolation.
# Helper to build a test client without a real MySQL connection.
# Mirrors what initialize does for attribute setup.
def build_test_client(options)
  c = Trilogy.allocate
  c.instance_variable_set(:@connection_options, options)
  c.instance_variable_set(:@_otel_database_name, options[:database])
  c.instance_variable_set(:@_otel_base_attributes, c.send(:_build_otel_base_attributes).freeze)
  c
end

describe OpenTelemetry::Instrumentation::Trilogy::Patches::Old::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Trilogy::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  let(:connection_options) do
    {
      host: 'db-primary.example.com',
      database: 'myapp_production',
      username: 'app_user'
    }
  end

  let(:client) { build_test_client(connection_options) }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('old')

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
    it 'includes db.system as mysql' do
      attrs = client.send(:client_attributes)
      assert_equal 'mysql', attrs[OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM]
    end

    it 'includes net.peer.name from host option' do
      attrs = client.send(:client_attributes)
      assert_equal 'db-primary.example.com', attrs[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]
    end

    it 'includes db.name from database option' do
      attrs = client.send(:client_attributes)
      assert_equal 'myapp_production', attrs[OpenTelemetry::SemanticConventions::Trace::DB_NAME]
    end

    it 'includes db.user from username option' do
      attrs = client.send(:client_attributes)
      assert_equal 'app_user', attrs[OpenTelemetry::SemanticConventions::Trace::DB_USER]
    end

    it 'falls back to unknown sock when host is nil' do
      c = build_test_client({ database: 'test' })
      attrs = c.send(:client_attributes)
      assert_equal 'unknown sock', attrs[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME]
    end

    it 'omits db.name when database is nil' do
      c = build_test_client({ host: 'h' })
      attrs = c.send(:client_attributes)
      refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_NAME)
    end

    it 'omits db.user when username is nil' do
      c = build_test_client({ host: 'h' })
      attrs = c.send(:client_attributes)
      refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_USER)
    end

    it 'includes db.instance.id when connected_host is set' do
      client.instance_variable_set(:@connected_host, 'replica-3.internal')
      attrs = client.send(:client_attributes)
      assert_equal 'replica-3.internal', attrs['db.instance.id']
    end

    it 'omits db.instance.id when connected_host is nil' do
      attrs = client.send(:client_attributes)
      refute attrs.key?('db.instance.id')
    end

    it 'includes peer_service when configured' do
      instrumentation.instance_variable_set(:@installed, false)
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
      end

      it 'includes SQL when db_statement is :include' do
        instrumentation.install({
                                  db_statement: :include,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users')
        assert_equal 'SELECT * FROM users', attrs[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]
      end

      it 'omits SQL when db_statement is :omit' do
        instrumentation.install({
                                  db_statement: :omit,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users')
        refute attrs.key?(OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT)
      end

      it 'obfuscates SQL when db_statement is :obfuscate' do
        instrumentation.install({
                                  db_statement: :obfuscate,
                                  span_name: :statement_type,
                                  propagator: 'none',
                                  record_exception: true,
                                  obfuscation_limit: 2000,
                                  peer_service: nil
                                })
        attrs = client.send(:client_attributes, 'SELECT * FROM users WHERE id = 1')
        stmt = attrs[OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT]
        assert stmt, 'expected db.statement to be present'
        refute_includes stmt, '1'
      end
    end
  end
end