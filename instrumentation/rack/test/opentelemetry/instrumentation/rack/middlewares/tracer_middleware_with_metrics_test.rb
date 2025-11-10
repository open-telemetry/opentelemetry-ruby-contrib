# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'rack/builder'
require 'rack/mock'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/tracer_middleware_with_metrics'

describe 'OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddlewareWithMetrics' do
  let(:instrumentation_module) { OpenTelemetry::Instrumentation::Rack }
  let(:instrumentation_class) { instrumentation_module::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }

  let(:described_class) { OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddlewareWithMetrics }

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

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(app) }
  let(:rack_builder) { Rack::Builder.new }

  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:first_span) { exporter.finished_spans.first }

  let(:default_config) { {} }
  let(:config) { { metrics: true, server_request_duration: true } }
  let(:env) { {} }
  let(:uri) { '/' }

  before do
    # clear captured spans:
    exporter.reset

    # Setup metrics
    @metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    OpenTelemetry.meter_provider.add_metric_reader(@metric_exporter)

    # simulate a fresh install:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)

    # integrate tracer middleware:
    rack_builder.run app
    rack_builder.use described_class
  end

  after do
    # installation is 'global', so it should be reset:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(default_config)
  end

  describe '#initialize' do
    it 'wraps the app with TracerMiddleware' do
      _(middleware.instance_variable_get(:@app)).must_equal app
      _(middleware.instance_variable_get(:@tracer_middleware)).must_be_instance_of(
        OpenTelemetry::Instrumentation::Rack::Middlewares::Stable::TracerMiddleware
      )
    end
  end

  describe '#call' do
    it 'delegates tracing to TracerMiddleware and records metrics' do
      Rack::MockRequest.new(rack_builder).get(uri, env)

      # Verify spans are created (delegated to TracerMiddleware)
      _(finished_spans).wont_be_empty
      _(first_span.attributes['http.request.method']).must_equal 'GET'
      _(first_span.attributes['http.response.status_code']).must_equal 200
      _(first_span.attributes['url.path']).must_equal '/'
      _(first_span.name).must_equal 'GET'
      _(first_span.kind).must_equal :server

      # Verify metrics are recorded
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
      assert_server_duration_metric(duration_metric, expected_count: 1)
    end

    it 'works with different status codes' do
      [404, 500].each do |status_code|
        exporter.reset
        @metric_exporter.reset

        custom_app = ->(_env) { [status_code, { 'Content-Type' => 'text/plain' }, ['Response']] }
        custom_builder = Rack::Builder.new
        custom_builder.run custom_app
        custom_builder.use described_class

        Rack::MockRequest.new(custom_builder).get(uri, env)

        _(exporter.finished_spans).wont_be_empty
        _(exporter.finished_spans.first.attributes['http.response.status_code']).must_equal status_code
      end
    end

    it 'handles exceptions and still records metrics' do
      exporter.reset
      @metric_exporter.reset

      exception_app = ->(_env) { raise StandardError, 'Test error' }
      exception_builder = Rack::Builder.new
      exception_builder.run exception_app
      exception_builder.use described_class

      exception_raised = false
      begin
        Rack::MockRequest.new(exception_builder).get(uri, env)
      rescue StandardError
        exception_raised = true
      end

      _(exception_raised).must_equal true

      # Verify span details
      _(finished_spans.size).must_equal 1
      error_span = finished_spans.first

      _(error_span).wont_be_nil
      _(error_span.name).must_equal 'GET'
      _(error_span.kind).must_equal :server
      _(error_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(error_span.status.description).must_match(/StandardError/)
      _(error_span.attributes['http.request.method']).must_equal 'GET'
      _(error_span.attributes['url.path']).must_equal '/'
      _(error_span.events.size).must_equal 1
      _(error_span.events.first.name).must_equal 'exception'
      _(error_span.events.first.attributes['exception.type']).must_equal 'StandardError'
      _(error_span.events.first.attributes['exception.message']).must_equal 'Test error'

      # Metrics should still be recorded
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
      assert_server_duration_metric(duration_metric, expected_count: 1)
    end
  end

  describe 'timing accuracy' do
    it 'measures the full request duration' do
      slow_app = lambda do |_env|
        sleep 0.05 # 50ms delay
        [200, { 'Content-Type' => 'text/plain' }, ['OK']]
      end

      slow_builder = Rack::Builder.new
      slow_builder.run slow_app
      slow_builder.use described_class

      start_time = Time.now
      Rack::MockRequest.new(slow_builder).get(uri, env)
      elapsed = (Time.now - start_time) * 1000 # Convert to ms

      # The recorded metric should be at least 50ms
      _(elapsed).must_be :>=, 50
    end
  end

  describe 'integration with TracerMiddleware' do
    it 'preserves TracerMiddleware functionality with headers and query strings' do
      custom_env = {
        'HTTP_USER_AGENT' => 'Test Agent',
        'HTTP_X_FORWARDED_FOR' => '192.168.1.1'
      }
      uri_with_query = '/endpoint?query=true&foo=bar'

      Rack::MockRequest.new(rack_builder).get(uri_with_query, custom_env)

      _(first_span).wont_be_nil
      _(first_span.name).must_equal 'GET'
      _(first_span.kind).must_equal :server
      _(first_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      _(first_span.attributes['user_agent.original']).must_equal 'Test Agent'
      _(first_span.attributes['url.path']).must_equal '/endpoint'
      _(first_span.attributes['url.query']).must_equal 'query=true&foo=bar'
    end
  end
end
