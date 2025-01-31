# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)
require 'rack/events'
require 'opentelemetry-instrumentation-rack'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

METRICS_EXPORTER = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new

module MetricsPatch
  def metrics_configuration_hook
    OpenTelemetry.meter_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: @resource)
    OpenTelemetry.meter_provider.add_metric_reader(METRICS_EXPORTER)
  end
end

OpenTelemetry::SDK::Configurator.prepend(MetricsPatch)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end
