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
    instrumentation.install
    Rails.logger = main_logger.extend(ActiveSupport::Logger.broadcast(broadcasted_logger))
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

    it 'does not suppress direct log records after a broadcast' do
      broadcast_msg = "larch #{rand(6)}"
      direct_msg = "maple #{rand(6)}"

      Rails.logger.debug(broadcast_msg)
      broadcasted_logger.debug(direct_msg)

      log_record_bodies = EXPORTER.emitted_log_records.map(&:body)
      assert_equal 2, log_record_bodies.size
      assert(log_record_bodies.any? { |body| body.include?(broadcast_msg) })
      assert(log_record_bodies.any? { |body| body.include?(direct_msg) })
    end
  end
end
