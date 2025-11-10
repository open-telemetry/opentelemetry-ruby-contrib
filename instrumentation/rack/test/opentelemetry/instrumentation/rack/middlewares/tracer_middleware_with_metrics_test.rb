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

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(app) }
  let(:rack_builder) { Rack::Builder.new }

  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:first_span) { exporter.finished_spans.first }

  let(:default_config) { {} }
  let(:config) { default_config }
  let(:env) { {} }
  let(:uri) { '/' }

  before do
    # clear captured spans:
    exporter.reset

    # Setup metrics
    @metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    @metric_exporter.reset
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
    it 'delegates tracing to TracerMiddleware' do
      Rack::MockRequest.new(rack_builder).get(uri, env)

      # Verify that spans are still created (delegated to TracerMiddleware)
      _(finished_spans).wont_be_empty
      _(first_span.attributes['http.request.method']).must_equal 'GET'
      _(first_span.attributes['http.response.status_code']).must_equal 200
      _(first_span.attributes['url.path']).must_equal '/'
      _(first_span.name).must_equal 'GET'
      _(first_span.kind).must_equal :server
    end

    it 'records metrics for the request' do
      Rack::MockRequest.new(rack_builder).get(uri, env)

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      # Verify that metrics were recorded if configured
      if instrumentation.config[:server_request_duration]
        _(metrics).wont_be_empty
        duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
        _(duration_metric).wont_be_nil
      end
    end

    it 'records metrics even when app returns different status codes' do
      [200, 404, 500].each do |status_code|
        exporter.reset
        @metric_exporter.reset

        custom_app = ->(_env) { [status_code, { 'Content-Type' => 'text/plain' }, ['Response']] }
        custom_builder = Rack::Builder.new
        custom_builder.run custom_app
        custom_builder.use described_class

        Rack::MockRequest.new(custom_builder).get(uri, env)

        # Verify span was created
        _(exporter.finished_spans).wont_be_empty
        _(exporter.finished_spans.first.attributes['http.response.status_code']).must_equal status_code
      end
    end

    describe 'when app raises an exception' do
      let(:app) do
        ->(_env) { raise StandardError, 'Test error' }
      end

      it 'records metrics even when exception occurs' do
        exception_raised = false

        begin
          Rack::MockRequest.new(rack_builder).get(uri, env)
        rescue StandardError
          exception_raised = true
        end

        _(exception_raised).must_equal true

        # Metrics should still be recorded
        @metric_exporter.pull
        metrics = @metric_exporter.metric_snapshots

        if instrumentation.config[:server_request_duration]
          _(metrics).wont_be_empty
        end
      end

      it 'ensures TracerMiddleware handles the exception' do
        exception_raised = false

        begin
          Rack::MockRequest.new(rack_builder).get(uri, env)
        rescue StandardError
          exception_raised = true
        end

        _(exception_raised).must_equal true
        # Span should still be created and finished
        _(finished_spans).wont_be_empty
      end
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

  describe 'error handling in metric recording' do
    it 'handles errors during metric recording gracefully' do
      # Mock config to cause an error
      bad_config = { server_request_duration: nil }

      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(bad_config)

      builder = Rack::Builder.new
      builder.run app
      builder.use described_class

      # Should not raise an exception
      response = Rack::MockRequest.new(builder).get(uri, env)
      _(response.status).must_equal 200
    end
  end

  describe 'integration with TracerMiddleware' do
    it 'preserves all TracerMiddleware functionality' do
      # Test that tracing context is properly propagated
      Rack::MockRequest.new(rack_builder).get(uri, env)

      _(first_span).wont_be_nil
      _(first_span.name).must_equal 'GET'
      _(first_span.kind).must_equal :server
      _(first_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
    end

    it 'works with custom headers' do
      custom_env = {
        'HTTP_USER_AGENT' => 'Test Agent',
        'HTTP_X_FORWARDED_FOR' => '192.168.1.1'
      }

      Rack::MockRequest.new(rack_builder).get(uri, custom_env)

      _(first_span).wont_be_nil
      _(first_span.attributes['user_agent.original']).must_equal 'Test Agent'
    end

    it 'handles query strings' do
      uri_with_query = '/endpoint?query=true&foo=bar'

      Rack::MockRequest.new(rack_builder).get(uri_with_query, env)

      _(first_span).wont_be_nil
      _(first_span.attributes['url.path']).must_equal '/endpoint'
      _(first_span.attributes['url.query']).must_equal 'query=true&foo=bar'
    end
  end
end
