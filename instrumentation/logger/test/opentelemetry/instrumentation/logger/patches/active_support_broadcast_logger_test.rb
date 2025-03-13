# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

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

  describe '#add' do
    it 'emits the log to the broadcasted loggers' do
      body = 'Ground control to Major Tom'
      broadcast.add(Logger::DEBUG, body)

      assert_includes(LOG_STREAM.string, body)
      assert_includes(BROADCASTED_STREAM.string, body)
    end

    it 'emits only one OpenTelemetry log record' do
      body = 'Wake up, you sleepyhead'
      broadcast.add(Logger::DEBUG, body)
      log_records = EXPORTER.emitted_log_records

      assert_equal 1, log_records.size
      assert_equal 'DEBUG', log_records.first.severity_text
      assert_equal body, log_records.first.body
    end
  end

  describe '#unknown' do
    it 'emits the log to the broadcasted loggers' do
      body = 'I know when to go out'
      broadcast.unknown(body)

      assert_includes(LOG_STREAM.string, body)
      assert_includes(BROADCASTED_STREAM.string, body)
    end

    it 'emits only one OpenTelemetry log record' do
      body = "You've got your mother in a whirl"
      broadcast.unknown(body)

      log_records = EXPORTER.emitted_log_records

      assert_equal 1, log_records.size
      assert_equal 'ANY', log_records.first.severity_text
      assert_equal body, log_records.first.body
    end
  end

  %w[debug info warn error fatal].each do |severity|
    describe "##{severity}" do
      it 'emits the log to the broadcasted loggers' do
        body = "Still don't know what I was waiting for...#{rand(7)}"
        broadcast.send(severity.to_sym, body)

        assert_includes(LOG_STREAM.string, body)
        assert_includes(BROADCASTED_STREAM.string, body)
      end

      it 'emits only one OpenTelemetry log record' do
        body = "They pulled in just behind the bridge...#{rand(7)}"
        broadcast.send(severity.to_sym, body)

        log_records = EXPORTER.emitted_log_records

        assert_equal 1, log_records.size
        assert_equal severity.upcase, log_records.first.severity_text
        assert_equal body, log_records.first.body
      end
    end
  end
end
