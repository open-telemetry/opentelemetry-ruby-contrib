# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'httpx/adapters/webmock'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end

if defined?(OpenTelemetry::SDK::Metrics)
  ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'] ||= 'delta'

  METRIC_EXPORTER = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(METRIC_EXPORTER)
end
