# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../../lib/opentelemetry/instrumentation/redis/patches/redis_v4_client'

describe OpenTelemetry::Instrumentation::Redis::Patches::RedisV4Client do
  # NOTE: These tests should be run for redis v4 and redis v5, even though the patches won't be installed on v5.
  # Perhaps these tests should live in a different file?
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:password) { 'passw0rd' }
  let(:redis_host) { ENV['TEST_REDIS_HOST'] }
  let(:redis_port) { ENV['TEST_REDIS_PORT'].to_i }
  let(:last_span) { exporter.finished_spans.last }

  # Instantiate the Redis client with the correct password. Note that this
  # will generate one extra span on connect because the Redis client will
  # send an AUTH command before doing anything else.
  def redis_with_auth(redis_options = {})
    redis_options[:password] ||= password
    redis_options[:host] ||= redis_host
    redis_options[:port] ||= redis_port
    Redis.new(redis_options)
  end

  def redis_version
    Gem.loaded_specs['redis']&.version
  end

  def redis_version_major
    redis_version&.segments&.first
  end

  def redis_gte_5?
    redis_version_major&.>=(5)
  end

  let(:config) { { db_statement: :include } }

  before do
    # ensure obfuscation is off if it was previously set in a different test
    instrumentation.install(config)
    exporter.reset
  end

  # Force re-install of instrumentation
  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#process' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      Redis.new(host: redis_host, port: redis_port).auth(password)

      _(last_span.attributes['peer.service']).must_equal 'readonly:redis'
    end

    it 'context attributes take priority' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      redis = redis_with_auth

      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(last_span.attributes['peer.service']).must_equal 'foo'
    end

    it 'after authorization with Redis server' do
      Redis.new(host: redis_host, port: redis_port).auth(password)

      _(last_span.name).must_equal 'AUTH'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'after requests' do
      redis = redis_with_auth
      _(redis.set('K', 'x')).must_equal 'OK'
      _(redis.get('K')).must_equal 'x'

      _(exporter.finished_spans.size).must_equal 3

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['net.peer.port']).must_equal redis_port

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal 'GET K'
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      _(get_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'reflects db index' do
      redis = redis_with_auth(db: 1)
      redis.get('K')

      if redis_gte_5?
        _(exporter.finished_spans.size).must_equal 2
        select_span = exporter.finished_spans.first
        get_span = exporter.finished_spans.last
        _(select_span.name).must_equal 'PIPELINED'
        _(select_span.attributes['db.statement']).must_equal("AUTH ?\nSELECT 1")
      else
        _(exporter.finished_spans.size).must_equal 3

        select_span = exporter.finished_spans[1]
        _(select_span.name).must_equal 'SELECT'
        _(select_span.attributes['db.statement']).must_equal('SELECT 1')

        get_span = exporter.finished_spans.last
      end

      _(select_span.attributes['db.system']).must_equal 'redis'
      _(select_span.attributes['net.peer.name']).must_equal redis_host
      _(select_span.attributes['net.peer.port']).must_equal redis_port
      _(select_span.attributes['db.redis.database_index']).must_equal 1

      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      _(get_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'merges context attributes' do
      redis = redis_with_auth
      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.set('K', 'x')
      end

      _(exporter.finished_spans.size).must_equal 2

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['peer.service']).must_equal 'foo'
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'records exceptions' do
      expect do
        redis = redis_with_auth
        redis.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )

      if redis_gte_5?
        _(last_span.status.description.tr('`', "'")).must_include(
          'Unhandled exception of type: RedisClient::CommandError'
        )
      else
        _(last_span.status.description.tr('`', "'")).must_include(
          "ERR unknown command 'THIS_IS_NOT_A_REDIS_FUNC', with args beginning with: 'THIS_IS_NOT_A_VALID_ARG"
        )
      end
    end

    it 'records net.peer.name and net.peer.port attributes' do
      client = Redis.new(host: 'example.com', port: 8321, timeout: 0.01)
      expect { client.auth(password) }.must_raise Redis::CannotConnectError

      if redis_gte_5?
        skip(
          'Redis 5 is a wrapper around RedisClient, which calls' \
          '`ensure_connected` before any of the middlewares are invoked.' \
          'This is more appropriately instrumented via a `#connect` hook in the middleware.'
        )
      else
        _(last_span.name).must_equal 'AUTH'
        _(last_span.attributes['db.system']).must_equal 'redis'
        _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
        _(last_span.attributes['net.peer.name']).must_equal 'example.com'
        _(last_span.attributes['net.peer.port']).must_equal 8321
      end
    end

    it 'traces pipelined commands' do
      redis = redis_with_auth
      redis.pipelined do |r|
        r.set('v1', '0')
        r.incr('v1')
        r.get('v1')
      end

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'traces pipelined commands on commit' do
      redis = redis_with_auth
      redis.pipelined do |pipeline|
        pipeline.set('v1', '0')
        pipeline.incr('v1')
        pipeline.get('v1')
      end

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
    end

    it 'records floats' do
      redis = redis_with_auth
      redis.hmset('hash', 'f1', 1_234_567_890.0987654321)

      _(last_span.name).must_equal 'HMSET'
      _(last_span.attributes['db.statement']).must_equal 'HMSET hash f1 1234567890.0987654'
    end

    it 'records nil' do
      redis = redis_with_auth
      redis.set('K', nil)

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K '
    end

    it 'records empty string' do
      redis = redis_with_auth
      redis.set('K', '')

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K '
    end

    it 'truncates long db.statements' do
      redis = redis_with_auth
      the_long_value = 'y' * 100
      redis.pipelined do |pipeline|
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
        pipeline.set('v1', the_long_value)
      end

      expected_db_statement = <<~HEREDOC.chomp
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy...
      HEREDOC

      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.statement'].size).must_equal 500
      _(last_span.attributes['db.statement']).must_equal expected_db_statement
    end

    it 'encodes invalid byte sequences for db.statement' do
      redis = redis_with_auth

      # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
      redis.set('K', "x\255")

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K x'
    end

    describe 'when trace_root_spans is disabled' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(trace_root_spans: false)
      end

      it 'traces redis spans with a parent' do
        redis = redis_with_auth
        OpenTelemetry.tracer_provider.tracer('tester').in_span('a root!') do
          redis.set('a', 'b')
        end

        redis_span = exporter.finished_spans.find { |s| s.name == 'SET' }
        _(redis_span.name).must_equal 'SET'
        _(redis_span.attributes['db.statement']).must_equal 'SET ? ?'
      end

      it 'does not trace redis spans without a parent' do
        redis = redis_with_auth
        redis.set('a', 'b')

        _(exporter.finished_spans.size).must_equal 0
      end
    end

    describe 'when db_statement is :omit' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :omit)
      end

      it 'omits db.statement attribute' do
        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(redis.get('K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal(redis_gte_5? ? 'PIPELINED' : 'AUTH')
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
      end
    end

    describe 'when db_statement is :obfuscate' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :obfuscate)
      end

      it 'obfuscates arguments in db.statement' do
        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(redis.get('K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal(redis_gte_5? ? 'PIPELINED' : 'AUTH')
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'AUTH ?'
        )

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'SET ? ?'
        )

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal(
          'GET ?'
        )
      end
    end
  end

  if defined?(OpenTelemetry::Metrics)
    describe 'metrics not enabled' do
      it 'will not be enabled' do
        assert(instrumentation.metrics_defined?)
        refute(instrumentation.metrics_enabled?)
      end
    end

    describe 'metrics enabled' do
      let(:config) { { db_statement: :include, metrics: true } }
      let(:metric_snapshot) do
        metrics_exporter.pull
        metrics_exporter.metric_snapshots.last
      end

      it 'will be enabled' do
        assert(instrumentation.metrics_defined?)
        assert(instrumentation.metrics_enabled?)
      end

      it 'works', with_metrics_sdk: true do
        skip if redis_gte_5?

        redis = redis_with_auth
        key = SecureRandom.hex
        10.times { redis.incr(key) }
        redis.expire(key, 1)

        _(metric_snapshot.data_points.length).must_equal(3)

        metric_snapshot.data_points.each do |data_point|
          _(data_point.attributes['db.system']).must_equal('redis')
        end

        by_operation_name = metric_snapshot.data_points.each_with_object({}) { |d, res| res[d.attributes['db.operation.name']] = d }
        _(by_operation_name.keys.sort).must_equal(%w[auth expire incr])

        _(by_operation_name['auth'].count).must_equal(1)
        _(by_operation_name['incr'].count).must_equal(10)
        _(by_operation_name['expire'].count).must_equal(1)
      end

      it 'works v5', with_metrics_sdk: true do
        skip unless redis_gte_5?

        redis = redis_with_auth
        key = SecureRandom.hex
        10.times { redis.incr(key) }
        redis.expire(key, 1)

        _(metric_snapshot.data_points.length).must_equal(3)

        metric_snapshot.data_points.each do |data_point|
          _(data_point.attributes['db.system']).must_equal('redis')
        end

        by_operation_name = metric_snapshot.data_points.each_with_object({}) { |d, res| res[d.attributes['db.operation.name']] = d }
        _(by_operation_name.keys.sort).must_equal(%w[PIPELINED expire incr])

        _(by_operation_name['PIPELINED'].count).must_equal(1)
        _(by_operation_name['incr'].count).must_equal(10)
        _(by_operation_name['expire'].count).must_equal(1)
      end

      it 'adds errors', with_metrics_sdk: true do
        skip if redis_gte_5?

        redis = redis_with_auth
        key = SecureRandom.hex
        redis.setex(key, 100, 'string_value')
        expect { redis.incr(key) }.must_raise(Redis::CommandError)

        last_data_point = metric_snapshot.data_points.last
        _(last_data_point.attributes['db.operation.name']).must_equal('incr')
        _(last_data_point.attributes['error.type']).must_be_instance_of(String)
        _(last_data_point.attributes['error.type']).must_equal('Redis::CommandError')
      end

      it 'adds errors v5', with_metrics_sdk: true do
        skip unless redis_gte_5?

        redis = redis_with_auth
        key = SecureRandom.hex
        redis.setex(key, 100, 'string_value')
        expect { redis.incr(key) }.must_raise(Redis::CommandError)

        last_data_point = metric_snapshot.data_points.last
        _(last_data_point.attributes['db.operation.name']).must_equal('incr')
        _(last_data_point.attributes['error.type']).must_equal('RedisClient::CommandError')
      end
    end
  end
end unless ENV['OMIT_SERVICES']
