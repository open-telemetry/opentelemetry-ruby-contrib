# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'pg'

require_relative '../../../../../lib/opentelemetry/instrumentation/pg'
require_relative '../../../../../lib/opentelemetry/instrumentation/pg/patches/connection'

describe OpenTelemetry::Instrumentation::PG::Patches do
  let(:instrumentation) { OpenTelemetry::Instrumentation::PG::Instrumentation.instance }
  let(:config) { {} }
  let(:host) { ENV.fetch('TEST_POSTGRES_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_POSTGRES_PORT', '5432') }
  let(:user) { ENV.fetch('TEST_POSTGRES_USER', 'postgres') }
  let(:dbname) { ENV.fetch('TEST_POSTGRES_DB', 'postgres') }
  let(:password) { ENV.fetch('TEST_POSTGRES_PASSWORD', 'postgres') }
  let(:client) { PG::Connection.open(host: host, port: port, user: user, dbname: dbname, password: password) }

  before do
    instrumentation.install(config)
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'patched PG::Connection' do
    %i[exec query sync_exec async_exec].each do |method|
      describe "method #{method}" do
        it 'responds with expected values when called with a block' do
          values = client.send(method, 'SELECT 1') { |result| result.column_values(0) }
          _(values).must_equal(['1'])
        end

        it 'responds with expected values when called via dot syntax' do
          values = client.send(method, 'SELECT 1').column_values(0)
          _(values).must_equal(['1'])
        end
      end
    end

    %i[exec_params async_exec_params sync_exec_params].each do |method|
      describe "method #{method}" do
        it 'responds with expected values when called with a block' do
          values = client.send(method, 'SELECT $1 AS a', [1]) { |result| result.column_values(0) }
          _(values).must_equal(['1'])
        end

        it 'responds with expected values when called via dot syntax' do
          values = client.send(method, 'SELECT $1 AS a', [1]).column_values(0)
          _(values).must_equal(['1'])
        end
      end
    end

    %i[exec_prepared async_exec_prepared sync_exec_prepared].each do |method|
      describe "method #{method}" do
        it 'responds with expected values when called with a block' do
          client.prepare('foo', 'SELECT $1 AS a')
          values = client.send(method, 'foo', [1]) { |result| result.column_values(0) }
          _(values).must_equal(['1'])
        end

        it 'responds with expected values when called via dot syntax' do
          client.prepare('foo', 'SELECT $1 AS a')
          values = client.send(method, 'foo', [1]).column_values(0)
          _(values).must_equal(['1'])
        end
      end
    end

    it 'can execute a pipeline of SELECT queries' do
      #
      # From https://www.postgresql.org/docs/current/libpq-pipeline-mode.html#LIBPQ-PIPELINE-RESULTS
      #
      # To process the result of one query in a pipeline, the application
      # calls PQgetResult repeatedly and handles each result until
      # PQgetResult returns null.
      #
      # The result from the next query in the pipeline may then be retrieved
      # using PQgetResult again and the cycle repeated. The application
      # handles individual statement results as normal.
      #
      # When the results of all the queries in the pipeline have been
      # returned, PQgetResult returns a result containing the status value
      # PGRES_PIPELINE_SYNC
      #
      client.enter_pipeline_mode
      client.send_query_params('SELECT $1', [1])
      client.send_query_params('SELECT $1', [2])
      client.pipeline_sync

      assert_equal(['1'], client.get_result.column_values(0))
      assert_nil(client.get_result)

      assert_equal(['2'], client.get_result.column_values(0))
      assert_nil(client.get_result)

      assert_equal(PG::Constants::PGRES_PIPELINE_SYNC, client.get_result.result_status)

      client.exit_pipeline_mode
    end
  end unless ENV['OMIT_SERVICES']
end
