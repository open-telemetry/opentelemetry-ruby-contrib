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

# Helper method to verify metric structure
def assert_server_duration_metric(metric, expected_count: nil)
  _(metric).wont_be_nil
  _(metric.name).must_equal 'http.server.request.duration'
  _(metric.description).must_equal 'Duration of HTTP server requests.'
  _(metric.unit).must_equal 'ms'
  _(metric.instrument_kind).must_equal :histogram
  _(metric.instrumentation_scope.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
  _(metric.data_points).wont_be_empty
  _(metric.data_points.first.count).must_equal expected_count if expected_count
end

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end
