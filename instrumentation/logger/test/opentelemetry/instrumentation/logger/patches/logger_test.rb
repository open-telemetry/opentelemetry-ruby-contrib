# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/logger/patches/logger'

describe OpenTelemetry::Instrumentation::Logger::Patches::Logger do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Logger::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:log_record) { exporter.emitted_log_records.first }
  let(:log_stream) { StringIO.new }
  let(:ruby_logger) { Logger.new(log_stream) }
  let(:msg) { 'message' }
  let(:config) { {} }

  before do
    exporter.reset
    instrumentation.install(config)
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#format_message' do
    it 'logs the formatted message to the correct source' do
      ruby_logger.debug(msg)
      assert_match(/DEBUG -- : #{msg}/, log_stream.string)
    end

    it 'sets the OTel logger instrumentation name and version (default case)' do
      ruby_logger.debug(msg)
      assert_equal(OpenTelemetry::Instrumentation::Logger::NAME, log_record.instrumentation_scope.name)
      assert_equal(OpenTelemetry::Instrumentation::Logger::VERSION, log_record.instrumentation_scope.version)
    end

    it 'sets log record attributes based on the Ruby log' do
      timestamp = Time.now
      nano_timestamp = OpenTelemetry::SDK::Logs::LogRecord.new.send(:to_integer_nanoseconds, timestamp)

      Time.stub(:now, timestamp) do
        ruby_logger.debug(msg)
        assert_equal(msg, log_record.body)
        assert_equal('DEBUG', log_record.severity_text)
        assert_equal(5, log_record.severity_number)
        assert_equal(nano_timestamp, log_record.timestamp)
      end
    end

    it 'does not emit when @skip_otel_emit is true' do
      ruby_logger.instance_variable_set(:@skip_otel_emit, true)
      ruby_logger.debug(msg)
      assert_nil(log_record)
    end

    it 'turns the severity into a number' do
      ruby_logger.debug(msg)
      assert_equal(5, log_record.severity_number)
    end

    it 'safely handles unknown severity number translations' do
      ruby_logger.send(:format_message, 'CUSTOM_SEVERITY', Time.now, nil, msg)
      assert_equal(0, log_record.severity_number)
    end
  end
end
