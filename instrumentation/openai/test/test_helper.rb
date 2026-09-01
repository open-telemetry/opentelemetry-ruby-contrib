# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'webmock/minitest'
require 'openai'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

# global opentelemetry-logs-sdk setup:
if defined?(OpenTelemetry::SDK::Logs)
  LOG_EXPORTER = OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter.new
  log_record_processor = OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(LOG_EXPORTER)
else
  LogExporter = Struct.new do
    def reset; end
    def emitted_log_records
      []
    end
  end

  LOG_EXPORTER = LogExporter.new
  log_record_processor = nil
end

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
  c.add_log_record_processor log_record_processor
end
