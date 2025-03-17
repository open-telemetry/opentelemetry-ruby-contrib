# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/logger/patches/active_support_logger'

describe OpenTelemetry::Instrumentation::Logger::Patches::ActiveSupportLogger do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Logger::Instrumentation.instance }
  let(:main_logger) { ActiveSupport::Logger.new(LOG_STREAM) }
  let(:broadcasted_logger) { ActiveSupport::Logger.new(BROADCASTED_STREAM) }

  before do
    skip unless defined?(ActiveSupport::Logger) && !defined?(ActiveSupport::BroadcastLogger)
    EXPORTER.reset
    Rails.logger = main_logger.extend(ActiveSupport::Logger.broadcast(broadcasted_logger))
    instrumentation.install
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#broadcast' do
    it 'streams the log to the Rails.logger' do
      msg = "spruce #{rand(6)}"
      Rails.logger.debug(msg)

      assert_match(/#{msg}/, LOG_STREAM.string)
    end

    it 'streams the broadcasted log' do
      msg = "willow #{rand(6)}"
      Rails.logger.debug(msg)

      assert_match(/#{msg}/, BROADCASTED_STREAM.string)
    end

    it 'emits the log record' do
      msg = "hemlock #{rand(6)}"
      Rails.logger.debug(msg)
      log_record = EXPORTER.emitted_log_records.first

      assert_match(/#{msg}/, log_record.body)
    end

    it 'emits the log record only once' do
      msg = "juniper #{rand(6)}"
      Rails.logger.debug(msg)

      log_records = EXPORTER.emitted_log_records
      assert_equal 1, log_records.size
      assert_match(/#{msg}/, log_records.first.body)
    end
  end
end
