# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'timeout'

require_relative '../../../../../lib/opentelemetry/instrumentation/logger/patches/active_support_broadcast_logger'

describe OpenTelemetry::Instrumentation::Logger::Patches::ActiveSupportBroadcastLogger do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Logger::Instrumentation.instance }
  let(:logger) { Logger.new(LOG_STREAM) }
  let(:logger2) { Logger.new(BROADCASTED_STREAM) }
  let(:broadcast) { ActiveSupport::BroadcastLogger.new(logger, logger2) }

  before do
    skip unless defined?(ActiveSupport::BroadcastLogger)
    EXPORTER.reset
    instrumentation.install
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  it 'does not suppress direct log records from other threads' do
    started_queue = Queue.new
    continue_queue = Queue.new
    blocking_logger_class = Class.new(Logger) do
      attr_accessor :started_queue, :continue_queue

      def format_message(...)
        started_queue << true
        continue_queue.pop
        super
      end
    end
    blocking_logger = blocking_logger_class.new(LOG_STREAM)
    blocking_logger.started_queue = started_queue
    blocking_logger.continue_queue = continue_queue
    blocking_broadcast = ActiveSupport::BroadcastLogger.new(blocking_logger, logger2)

    broadcast_body = 'One hand washes the other'
    direct_body = 'Other hand checks the thread'
    broadcast_thread = Thread.new { blocking_broadcast.info(broadcast_body) }

    begin
      Timeout.timeout(5) { started_queue.pop }
      logger2.info(direct_body)
    ensure
      continue_queue.push(true)
      broadcast_thread.value
    end

    log_record_bodies = EXPORTER.emitted_log_records.map(&:body)
    assert_equal 2, log_record_bodies.size
    assert(log_record_bodies.any? { |body| body.include?(broadcast_body) })
    assert(log_record_bodies.any? { |body| body.include?(direct_body) })
  end

  it 'does not suppress direct log records from other fibers' do
    blocking_logger_class = Class.new(Logger) do
      attr_accessor :on_format

      def format_message(...)
        on_format.call
        super
      end
    end
    blocking_logger = blocking_logger_class.new(LOG_STREAM)
    blocking_logger.on_format = -> { Fiber.yield }
    blocking_broadcast = ActiveSupport::BroadcastLogger.new(blocking_logger, logger2)

    broadcast_body = 'Turn and face the strange'
    direct_body = 'Different fiber keeps its voice'
    broadcast_fiber = Fiber.new { blocking_broadcast.info(broadcast_body) }

    begin
      broadcast_fiber.resume
      logger2.info(direct_body)
    ensure
      broadcast_fiber.resume if broadcast_fiber.alive?
    end

    log_record_bodies = EXPORTER.emitted_log_records.map(&:body)
    assert_equal 2, log_record_bodies.size
    assert(log_record_bodies.any? { |body| body.include?(broadcast_body) })
    assert(log_record_bodies.any? { |body| body.include?(direct_body) })
  end

  describe '#add' do
    it 'emits the log to the broadcasted loggers' do
      body = 'Ground control to Major Tom'
      return_value = broadcast.add(Logger::DEBUG, body)

      assert_includes(LOG_STREAM.string, body)
      assert_includes(BROADCASTED_STREAM.string, body)
      assert return_value
    end

    it 'emits only one OpenTelemetry log record' do
      body = 'Wake up, you sleepyhead'
      broadcast.add(Logger::DEBUG, body)
      log_records = EXPORTER.emitted_log_records

      assert_equal 1, log_records.size
      assert_equal 'DEBUG', log_records.first.severity_text
      assert_includes log_records.first.body, 'DEBUG'
      assert_includes log_records.first.body, body
    end
  end

  describe '#unknown' do
    it 'emits the log to the broadcasted loggers' do
      body = 'I know when to go out'
      return_value = broadcast.unknown(body)

      assert_includes(LOG_STREAM.string, body)
      assert_includes(BROADCASTED_STREAM.string, body)
      assert return_value
    end

    it 'emits only one OpenTelemetry log record' do
      body = "You've got your mother in a whirl"
      broadcast.unknown(body)

      log_records = EXPORTER.emitted_log_records

      assert_equal 1, log_records.size
      assert_equal 'ANY', log_records.first.severity_text
      assert_includes log_records.first.body, 'ANY'
      assert_includes log_records.first.body, body
    end
  end

  %w[debug info warn error fatal].each do |severity|
    describe "##{severity}" do
      it 'emits the log to the broadcasted loggers' do
        body = "Still don't know what I was waiting for...#{rand(7)}"
        return_value = broadcast.send(severity.to_sym, body)

        assert_includes(LOG_STREAM.string, body)
        assert_includes(BROADCASTED_STREAM.string, body)
        assert return_value
      end

      it 'emits only one OpenTelemetry log record' do
        body = "They pulled in just behind the bridge...#{rand(7)}"
        broadcast.send(severity.to_sym, body)

        log_records = EXPORTER.emitted_log_records

        assert_equal 1, log_records.size
        assert_equal severity.upcase, log_records.first.severity_text
        assert_includes log_records.first.body, severity.upcase
        assert_includes log_records.first.body, body
      end
    end
  end
end
