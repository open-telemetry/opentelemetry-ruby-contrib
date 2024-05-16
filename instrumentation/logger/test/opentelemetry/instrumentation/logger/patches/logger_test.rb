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

    describe 'configuration options' do
      describe 'when a user configures name' do
        let(:config) { { name: 'custom_logger' } }

        it 'updates the logger name' do
          ruby_logger.debug(msg)
          assert_equal('custom_logger', log_record.instrumentation_scope.name)
        end

        it 'uses the default version' do
          ruby_logger.debug(msg)
          assert_equal(OpenTelemetry::Instrumentation::Logger::VERSION, log_record.instrumentation_scope.version)
        end
      end

      describe 'when a user configures version' do
        let(:config) { { version: '5000' } }

        it 'updates the logger version' do
          ruby_logger.debug(msg)
          assert_equal('5000', log_record.instrumentation_scope.version)
        end

        it 'uses the default name' do
          ruby_logger.debug(msg)
          assert_equal(OpenTelemetry::Instrumentation::Logger::NAME, log_record.instrumentation_scope.name)
        end
      end

      describe 'when a user configures both name and version' do
        let(:config) { { name: 'custom_logger', version: '5000' } }

        it 'updates both values' do
          ruby_logger.debug(msg)
          assert_equal('custom_logger', log_record.instrumentation_scope.name)
          assert_equal('5000', log_record.instrumentation_scope.version)
        end
      end
    end

    it 'sets log record attributes based on the Ruby log' do
      timestamp = Time.now
      Time.stub(:now, timestamp) do
        ruby_logger.debug(msg)
        assert_equal(msg, log_record.body)
        assert_equal('DEBUG', log_record.severity_text)
        assert_equal(5, log_record.severity_number)
        assert_equal(timestamp, log_record.timestamp)
      end
    end

    it 'does not emit when @skip_instrumenting is true' do
      ruby_logger.instance_variable_set(:@skip_instrumenting, true)
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
