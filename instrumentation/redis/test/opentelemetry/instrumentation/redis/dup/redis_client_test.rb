# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../../lib/opentelemetry/instrumentation/redis/middlewares/dup/redis_client'

# Tests for dup semantic convention mode (both old and stable attributes) via RedisClient middleware
describe OpenTelemetry::Instrumentation::Redis::Middlewares::Dup::RedisClientInstrumentation do
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
    RedisClient.new(**redis_options).tap do |client|
      client.send(:raw_connection) # force lazy client to connect
    end
  end

  before do
    skip unless ENV['BUNDLE_GEMFILE']&.include?('dup')

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database/dup'
    config = { db_statement: :include }
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
      redis_with_auth

      _(last_span.attributes['peer.service']).must_equal 'readonly:redis'
    end

    it 'context attributes take priority' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')
      redis = redis_with_auth

      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.call('set', 'K', 'x')
      end

      _(last_span.attributes['peer.service']).must_equal 'foo'
    end

    it 'after authorization with Redis server includes both old and new attributes' do
      client = redis_with_auth

      _(client.connected?).must_equal(true)

      _(last_span.name).must_equal 'PIPELINE'
      # Old attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'HELLO ? ? ? ?'
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
      # New attributes
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.query.text']).must_equal 'HELLO ? ? ? ?'
      _(last_span.attributes['server.address']).must_equal redis_host
      # server.port only included if non-default (6379)
      _(last_span.attributes['server.port']).must_equal redis_port if redis_port != 6379
    end

    it 'after calling auth lowercase' do
      client = redis_with_auth
      client.call('auth', password)

      _(last_span.name).must_equal 'AUTH'
      # Old attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
      # New attributes
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.query.text']).must_equal 'AUTH ?'
      _(last_span.attributes['server.address']).must_equal redis_host
    end

    it 'after calling AUTH uppercase' do
      client = redis_with_auth
      client.call('AUTH', password)

      _(last_span.name).must_equal 'AUTH'
      # Old attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['net.peer.port']).must_equal redis_port
      # New attributes
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.query.text']).must_equal 'AUTH ?'
      _(last_span.attributes['server.address']).must_equal redis_host
    end

    it 'after requests includes both old and new attributes' do
      redis = redis_with_auth
      _(redis.call('set', 'K', 'x')).must_equal 'OK'
      _(redis.call('get', 'K')).must_equal 'x'

      _(exporter.finished_spans.size).must_equal 3

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      # Old attributes
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['net.peer.port']).must_equal redis_port
      # New attributes
      _(set_span.attributes['db.system.name']).must_equal 'redis'
      _(set_span.attributes['db.query.text']).must_equal('SET K x')
      _(set_span.attributes['server.address']).must_equal redis_host

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      # Old attributes
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal 'GET K'
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      # New attributes
      _(get_span.attributes['db.system.name']).must_equal 'redis'
      _(get_span.attributes['db.query.text']).must_equal 'GET K'
      _(get_span.attributes['server.address']).must_equal redis_host
    end

    it 'reflects db index' do
      redis = redis_with_auth(db: 1)
      redis.call('get', 'K')

      _(exporter.finished_spans.size).must_equal 2

      prelude_span = exporter.finished_spans.first
      _(prelude_span.name).must_equal 'PIPELINE'
      # Both old and new attributes
      _(prelude_span.attributes['db.system']).must_equal 'redis'
      _(prelude_span.attributes['db.system.name']).must_equal 'redis'
      _(prelude_span.attributes['db.statement']).must_equal("HELLO ? ? ? ?\nSELECT 1")
      _(prelude_span.attributes['db.query.text']).must_equal("HELLO ? ? ? ?\nSELECT 1")
      _(prelude_span.attributes['net.peer.name']).must_equal redis_host
      _(prelude_span.attributes['server.address']).must_equal redis_host

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.system.name']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.query.text']).must_equal('GET K')
      # Both old and new namespace attributes
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['db.namespace']).must_equal '1'
      _(get_span.attributes['net.peer.name']).must_equal redis_host
      _(get_span.attributes['server.address']).must_equal redis_host
    end

    it 'merges context attributes' do
      redis = redis_with_auth
      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        redis.call('set', 'K', 'x')
      end

      _(exporter.finished_spans.size).must_equal 2

      set_span = exporter.finished_spans[1]
      _(set_span.name).must_equal 'SET'
      _(set_span.attributes['db.system']).must_equal 'redis'
      _(set_span.attributes['db.system.name']).must_equal 'redis'
      _(set_span.attributes['db.statement']).must_equal('SET K x')
      _(set_span.attributes['db.query.text']).must_equal('SET K x')
      _(set_span.attributes['peer.service']).must_equal 'foo'
      _(set_span.attributes['net.peer.name']).must_equal redis_host
      _(set_span.attributes['server.address']).must_equal redis_host
    end

    it 'records exceptions with error.type' do
      expect do
        redis = redis_with_auth
        redis.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise RedisClient::CommandError

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      # Both old and new attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['db.query.text']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['server.address']).must_equal redis_host
      # Redis error prefix is extracted for error.type and db.response.status_code
      _(last_span.attributes['error.type']).must_equal 'ERR'
      _(last_span.attributes['db.response.status_code']).must_equal 'ERR'
      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
    end

    it 'connect is uninstrumented' do
      error = _ { redis_with_auth(host: 'example.com', port: 8321, timeout: 0.01) }.must_raise StandardError
      # Ruby 4 changed the timeout error class
      # Prior to that the client library would wrap the timeout in a RedisClient::CannotConnectError
      _([IO::TimeoutError, RedisClient::CannotConnectError]).must_include error.class

      _(last_span).must_be_nil
    end

    it 'traces pipelined commands' do
      redis = redis_with_auth
      redis.pipelined do |r|
        r.call('set', 'v1', '0')
        r.call('incr', 'v1')
        r.call('get', 'v1')
      end

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINE'
      # Both old and new attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['db.query.text']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['server.address']).must_equal redis_host
    end

    it 'records floats' do
      redis = redis_with_auth
      redis.call('hmset', 'hash', 'f1', 1_234_567_890.0987654321)

      _(last_span.name).must_equal 'HMSET'
      _(last_span.attributes['db.statement']).must_equal 'HMSET hash f1 1234567890.0987654'
      _(last_span.attributes['db.query.text']).must_equal 'HMSET hash f1 1234567890.0987654'
    end

    it 'records empty string' do
      redis = redis_with_auth
      redis.call('set', 'K', '')

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K '
      _(last_span.attributes['db.query.text']).must_equal 'SET K '
    end

    it 'truncates long statements' do
      redis = redis_with_auth
      the_long_value = 'y' * 100
      redis.pipelined do |pipeline|
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
        pipeline.call(:set, 'v1', the_long_value)
      end

      expected_statement = <<~HEREDOC.chomp
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
        SET v1 yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy...
      HEREDOC

      _(last_span.name).must_equal 'PIPELINE'
      _(last_span.attributes['db.statement'].size).must_equal 500
      _(last_span.attributes['db.statement']).must_equal expected_statement
      _(last_span.attributes['db.query.text'].size).must_equal 500
      _(last_span.attributes['db.query.text']).must_equal expected_statement
    end

    it 'encodes invalid byte sequences' do
      redis = redis_with_auth

      # \255 is off-limits https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
      redis.call('set', 'K', "x\255")

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K x'
      _(last_span.attributes['db.query.text']).must_equal 'SET K x'
    end

    describe 'when trace_root_spans is disabled' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(trace_root_spans: false)
      end

      it 'traces redis spans with a parent' do
        redis = redis_with_auth
        OpenTelemetry.tracer_provider.tracer('tester').in_span('a root!') do
          redis.call('set', 'a', 'b')
        end

        redis_span = exporter.finished_spans.find { |s| s.name == 'SET' }
        _(redis_span.name).must_equal 'SET'
        _(redis_span.attributes['db.statement']).must_equal 'SET ? ?'
        _(redis_span.attributes['db.query.text']).must_equal 'SET ? ?'
      end

      it 'does not trace redis spans without a parent' do
        redis = redis_with_auth
        redis.call('set', 'a', 'b')

        _(exporter.finished_spans.size).must_equal 0
      end
    end

    describe 'when db_statement is :omit' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :omit)
      end

      it 'omits both db.statement and db.query.text attributes' do
        redis = redis_with_auth
        _(redis.call('set', 'K', 'xyz')).must_equal 'OK'
        _(redis.call('get', 'K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal 'PIPELINE' # AUTH
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
        _(set_span.attributes).wont_include('db.query.text')

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
        _(set_span.attributes).wont_include('db.query.text')

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
        _(set_span.attributes).wont_include('db.query.text')
      end
    end

    describe 'when db_statement is :obfuscate' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :obfuscate)
      end

      it 'obfuscates arguments in both db.statement and db.query.text' do
        redis = redis_with_auth
        _(redis.call('set', 'K', 'xyz')).must_equal 'OK'
        _(redis.call('get', 'K')).must_equal 'xyz'
        _(exporter.finished_spans.size).must_equal 3

        set_span = exporter.finished_spans[0]
        _(set_span.name).must_equal 'PIPELINE'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal('HELLO ? ? ? ?')
        _(set_span.attributes['db.query.text']).must_equal('HELLO ? ? ? ?')

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal('SET ? ?')
        _(set_span.attributes['db.query.text']).must_equal('SET ? ?')

        set_span = exporter.finished_spans[2]
        _(set_span.name).must_equal 'GET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes['db.statement']).must_equal('GET ?')
        _(set_span.attributes['db.query.text']).must_equal('GET ?')
      end
    end
  end
end unless ENV['OMIT_SERVICES']
