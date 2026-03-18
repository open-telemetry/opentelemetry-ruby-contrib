# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../../lib/opentelemetry/instrumentation/redis/patches/dup/redis_v4_client'

# Tests for dup semantic convention mode (both old and stable attributes)
describe OpenTelemetry::Instrumentation::Redis::Patches::Dup::RedisV4Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:password) { 'passw0rd' }
  let(:redis_host) { ENV.fetch('TEST_REDIS_HOST', nil) }
  let(:redis_port) { ENV['TEST_REDIS_PORT'].to_i }
  let(:last_span) { exporter.finished_spans.last }

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

  before do
    skip unless ENV['BUNDLE_GEMFILE']&.include?('dup')

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database/dup'
    config = { db_statement: :include }
    instrumentation.install(config)
    exporter.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#process' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after authorization with Redis server includes both old and new attributes' do
      Redis.new(host: redis_host, port: redis_port).auth(password)

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
      # server.port only included if non-default (6379)
      _(last_span.attributes['server.port']).must_equal redis_port if redis_port != 6379
    end

    it 'after requests includes both old and new attributes' do
      redis = redis_with_auth
      _(redis.set('K', 'x')).must_equal 'OK'
      _(redis.get('K')).must_equal 'x'

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
      skip if redis_gte_5?

      redis = redis_with_auth(db: 1)
      redis.get('K')

      _(exporter.finished_spans.size).must_equal 3

      select_span = exporter.finished_spans[1]
      _(select_span.name).must_equal 'SELECT'
      # Both attributes
      _(select_span.attributes['db.statement']).must_equal('SELECT 1')
      _(select_span.attributes['db.query.text']).must_equal('SELECT 1')
      _(select_span.attributes['db.system']).must_equal 'redis'
      _(select_span.attributes['db.system.name']).must_equal 'redis'
      # Both old and new namespace attributes
      _(select_span.attributes['db.redis.database_index']).must_equal 1
      _(select_span.attributes['db.namespace']).must_equal '1'

      get_span = exporter.finished_spans.last
      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.system.name']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.query.text']).must_equal('GET K')
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['db.namespace']).must_equal '1'
    end

    it 'reflects db index v5' do
      skip unless redis_gte_5?

      redis = redis_with_auth(db: 1)
      redis.get('K')

      _(exporter.finished_spans.size).must_equal 2
      select_span = exporter.finished_spans.first
      get_span = exporter.finished_spans.last
      _(select_span.name).must_equal 'PIPELINE'
      # Both attributes
      _(select_span.attributes['db.statement']).must_equal("AUTH ?\nSELECT 1")
      _(select_span.attributes['db.query.text']).must_equal("AUTH ?\nSELECT 1")
      _(select_span.attributes['db.system']).must_equal 'redis'
      _(select_span.attributes['db.system.name']).must_equal 'redis'
      # Both old and new namespace attributes
      _(select_span.attributes['db.redis.database_index']).must_equal 1
      _(select_span.attributes['db.namespace']).must_equal '1'

      _(get_span.name).must_equal 'GET'
      _(get_span.attributes['db.system']).must_equal 'redis'
      _(get_span.attributes['db.system.name']).must_equal 'redis'
      _(get_span.attributes['db.statement']).must_equal('GET K')
      _(get_span.attributes['db.query.text']).must_equal('GET K')
      _(get_span.attributes['db.redis.database_index']).must_equal 1
      _(get_span.attributes['db.namespace']).must_equal '1'
    end

    it 'records exceptions with error.type' do
      skip if redis_gte_5?

      expect do
        redis = redis_with_auth
        redis.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      # Both attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['db.query.text']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      # Redis error prefix is extracted for error.type and db.response.status_code
      _(last_span.attributes['error.type']).must_equal 'ERR'
      _(last_span.attributes['db.response.status_code']).must_equal 'ERR'
      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
    end

    it 'records exceptions with error.type v5' do
      skip unless redis_gte_5?

      expect do
        redis = redis_with_auth
        redis.call 'THIS_IS_NOT_A_REDIS_FUNC', 'THIS_IS_NOT_A_VALID_ARG'
      end.must_raise Redis::CommandError

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'THIS_IS_NOT_A_REDIS_FUNC'
      # Both attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      _(last_span.attributes['db.query.text']).must_equal(
        'THIS_IS_NOT_A_REDIS_FUNC THIS_IS_NOT_A_VALID_ARG'
      )
      # Redis error prefix is extracted for error.type and db.response.status_code
      _(last_span.attributes['error.type']).must_equal 'ERR'
      _(last_span.attributes['db.response.status_code']).must_equal 'ERR'
      _(last_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
    end

    it 'traces pipelined commands' do
      redis = redis_with_auth
      redis.pipelined do |r|
        r.set('v1', '0')
        r.incr('v1')
        r.get('v1')
      end

      _(exporter.finished_spans.size).must_equal 2
      _(last_span.name).must_equal 'PIPELINE'
      # Both attributes
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.system.name']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['db.query.text']).must_equal "SET v1 0\nINCR v1\nGET v1"
      _(last_span.attributes['net.peer.name']).must_equal redis_host
      _(last_span.attributes['server.address']).must_equal redis_host
    end

    describe 'when db_statement is :omit' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :omit)
      end

      it 'omits both db.statement and db.query.text attributes' do
        skip if redis_gte_5?

        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(exporter.finished_spans.size).must_equal 2

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
        _(set_span.attributes).wont_include('db.query.text')
      end

      it 'omits both db.statement and db.query.text attributes v5' do
        skip unless redis_gte_5?

        redis = redis_with_auth
        _(redis.set('K', 'xyz')).must_equal 'OK'
        _(exporter.finished_spans.size).must_equal 2

        set_span = exporter.finished_spans[1]
        _(set_span.name).must_equal 'SET'
        _(set_span.attributes['db.system']).must_equal 'redis'
        _(set_span.attributes['db.system.name']).must_equal 'redis'
        _(set_span.attributes).wont_include('db.statement')
        _(set_span.attributes).wont_include('db.query.text')
      end
    end
  end
end unless ENV['OMIT_SERVICES']
