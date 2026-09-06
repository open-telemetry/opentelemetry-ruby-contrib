# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/redis'
require_relative '../../../../../lib/opentelemetry/instrumentation/redis/patches/redis_v4_client'

# Unit-tests RedisV4Client#process against a fake client. The patch is only
# prepended when redis < 5, so the redis-5.x/redis-latest appraisals (and Ruby
# 4.0, where redis-4.x is not generated) never cover it via client_test.rb.
# Prepending the module onto a stub keeps it covered in every appraisal.
describe OpenTelemetry::Instrumentation::Redis::Patches::RedisV4Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:last_span) { exporter.finished_spans.last }

  # Stub Redis::Client; prepended patch runs #process first, super returns @reply.
  let(:fake_client_class) do
    Class.new do
      attr_reader :options, :processed_commands
      attr_writer :reply

      def initialize(options = {})
        @options = { host: 'redis.example.com', port: 6379, db: 0 }.merge(options)
        @reply = 'OK'
      end

      # super target for the patch's #process.
      def process(commands)
        @processed_commands = commands
        @reply
      end

      prepend OpenTelemetry::Instrumentation::Redis::Patches::RedisV4Client
    end
  end

  def build_client(options = {})
    fake_client_class.new(options)
  end

  before do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(db_statement: :include)
    exporter.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#process' do
    it 'creates a client span named after a single command' do
      client = build_client
      _(client.process([[:set, 'K', 'x']])).must_equal 'OK'

      _(exporter.finished_spans.size).must_equal 1
      _(last_span.name).must_equal 'SET'
      _(last_span.kind).must_equal :client
      _(last_span.attributes['db.system']).must_equal 'redis'
      _(last_span.attributes['db.statement']).must_equal 'SET K x'
      _(last_span.attributes['net.peer.name']).must_equal 'redis.example.com'
      _(last_span.attributes['net.peer.port']).must_equal 6379
    end

    it 'names multi-command batches PIPELINED' do
      client = build_client
      client.process([[:set, 'v1', '0'], [:incr, 'v1'], [:get, 'v1']])

      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
    end

    it 'unwraps the extra nesting produced by Redis#queue' do
      client = build_client
      client.process([[[:set, 'v1', '0']], [[:incr, 'v1']], [[:get, 'v1']]])

      _(last_span.name).must_equal 'PIPELINED'
      _(last_span.attributes['db.statement']).must_equal "SET v1 0\nINCR v1\nGET v1"
    end

    it 'records the db index when it is not the default' do
      client = build_client(db: 2)
      client.process([[:get, 'K']])

      _(last_span.attributes['db.redis.database_index']).must_equal 2
    end

    it 'omits the db index when it is the default database' do
      client = build_client(db: 0)
      client.process([[:get, 'K']])

      _(last_span.attributes).wont_include('db.redis.database_index')
    end

    it 'records the configured peer service' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'readonly:redis')

      client = build_client
      client.process([[:get, 'K']])

      _(last_span.attributes['peer.service']).must_equal 'readonly:redis'
    end

    it 'merges context attributes onto the span' do
      client = build_client
      OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'foo') do
        client.process([[:set, 'K', 'x']])
      end

      _(last_span.attributes['peer.service']).must_equal 'foo'
    end

    it 'obfuscates auth commands regardless of the db_statement option' do
      client = build_client
      client.process([[:auth, 'super-secret']])

      _(last_span.name).must_equal 'AUTH'
      _(last_span.attributes['db.statement']).must_equal 'AUTH ?'
    end

    it 'records exceptions and sets an error status when the reply is a CommandError' do
      client = build_client
      client.reply = Redis::CommandError.new('ERR boom')
      client.process([[:get, 'K']])

      _(last_span.name).must_equal 'GET'
      _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(last_span.status.description).must_include 'boom'
      _(last_span.events.map(&:name)).must_include 'exception'
    end

    it 'records floats without losing precision metadata' do
      client = build_client
      client.process([[:hmset, 'hash', 'f1', 1_234_567_890.0987654321]])

      _(last_span.name).must_equal 'HMSET'
      _(last_span.attributes['db.statement']).must_equal 'HMSET hash f1 1234567890.0987654'
    end

    it 'truncates long db.statement values to 500 characters' do
      client = build_client
      long_value = 'y' * 600
      client.process([[:set, 'v1', long_value]])

      _(last_span.attributes['db.statement'].size).must_equal 500
      _(last_span.attributes['db.statement']).must_match(/\.\.\.\z/)
    end

    it 'utf8-encodes invalid byte sequences in db.statement' do
      client = build_client
      # \255 is not a valid UTF-8 byte: https://en.wikipedia.org/wiki/UTF-8#Codepage_layout
      client.process([[:set, 'K', "x\255"]])

      _(last_span.name).must_equal 'SET'
      _(last_span.attributes['db.statement']).must_equal 'SET K x'
    end

    describe 'when db_statement is :omit' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :omit)
      end

      it 'does not set the db.statement attribute' do
        client = build_client
        client.process([[:set, 'K', 'secret']])

        _(last_span.name).must_equal 'SET'
        _(last_span.attributes).wont_include('db.statement')
      end
    end

    describe 'when db_statement is :obfuscate' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(db_statement: :obfuscate)
      end

      it 'replaces command arguments with placeholders' do
        client = build_client
        client.process([[:set, 'K', 'secret']])

        _(last_span.name).must_equal 'SET'
        _(last_span.attributes['db.statement']).must_equal 'SET ? ?'
      end
    end

    describe 'when trace_root_spans is disabled' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(trace_root_spans: false)
      end

      it 'traces commands that have a parent span' do
        client = build_client
        OpenTelemetry.tracer_provider.tracer('tester').in_span('a root!') do
          client.process([[:set, 'a', 'b']])
        end

        redis_span = exporter.finished_spans.find { |s| s.name == 'SET' }
        _(redis_span).wont_be_nil
        # db_statement defaults to :obfuscate since only trace_root_spans was configured
        _(redis_span.attributes['db.statement']).must_equal 'SET ? ?'
      end

      it 'does not trace root commands' do
        client = build_client
        _(client.process([[:set, 'a', 'b']])).must_equal 'OK'

        _(exporter.finished_spans.size).must_equal 0
      end
    end
  end
end
