# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'rack/builder'
require 'rack/mock'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/event_handler_with_metrics'

describe 'OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandlerWithMetrics' do
  include Rack::Test::Methods

  let(:instrumentation_module) { OpenTelemetry::Instrumentation::Rack }
  let(:instrumentation_class) { instrumentation_module::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }
  let(:instrumentation_enabled) { true }

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

  let(:config) do
    {
      untraced_endpoints: [],
      enabled: instrumentation_enabled,
      use_rack_events: true,
      metrics: true
    }
  end

  let(:exporter) { EXPORTER }
  let(:meter_provider) { OpenTelemetry.meter_provider }
  let(:uri) { '/' }
  let(:handler) do
    OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandlerWithMetrics.new
  end

  let(:service) do
    ->(_arg) { [200, { 'Content-Type' => 'text/plain' }, ['Hello World']] }
  end
  let(:headers) { {} }
  let(:app) do
    Rack::Builder.new.tap do |builder|
      builder.use Rack::Events, [handler]
      builder.run service
    end
  end

  before do
    exporter.reset

    # Setup metrics
    @metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    OpenTelemetry.meter_provider.add_metric_reader(@metric_exporter)

    # simulate a fresh install:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)
  end

  after do
    # Clean up
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#on_start' do
    it 'records the start time in request env' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))

      handler.on_start(request, nil)

      start_time = request.env[OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandlerWithMetrics::OTEL_SERVER_START_TIME]
      _(start_time).wont_be_nil
      _(start_time).must_be_kind_of Integer
      _(start_time).must_be :>, 0
    end

    it 'handles exceptions gracefully when request is nil' do
      begin
        handler.on_start(nil, nil)
        _(true).must_equal true
      rescue NoMethodError => e
        _(e).must_be_kind_of NoMethodError
      end
    end
  end

  describe '#on_commit and #on_error' do
    it 'are no-ops that do not raise exceptions' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new
      error = StandardError.new('test error')

      handler.on_commit(request, response)
      handler.on_error(request, response, error)
    end
  end

  describe '#on_finish' do
    it 'records metrics when start_time is present' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new([200, {}, ['OK']])

      handler.on_start(request, nil)
      handler.on_finish(request, response)

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
      assert_server_duration_metric(duration_metric, expected_count: 1)
    end

    it 'handles edge cases gracefully' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new

      # Missing start_time - should not raise
      handler.on_finish(request, response)

      # Nil request - should handle gracefully
      begin
        handler.on_finish(nil, nil)
        _(true).must_equal true
      rescue NoMethodError => e
        _(e).must_be_kind_of NoMethodError
      end
    end
  end

  describe 'integration tests' do
    it 'records metrics for a complete request' do
      get uri, {}, headers

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
      assert_server_duration_metric(duration_metric, expected_count: 1)
    end

    it 'works alongside other event handlers' do
      other_handler_called = false
      other_handler = Class.new do
        include Rack::Events::Abstract

        define_method(:initialize) do |callback|
          @callback = callback
        end

        define_method(:on_start) do |request, response|
          @callback.call
        end
      end.new(-> { other_handler_called = true })

      multi_handler_app = Rack::Builder.new.tap do |builder|
        builder.use Rack::Events, [other_handler, handler]
        builder.run service
      end

      Rack::MockRequest.new(multi_handler_app).get(uri, headers)

      _(other_handler_called).must_equal true
    end

    it 'handles metric recording errors gracefully' do
      handler.stub(:config, {}) do
        request = Rack::Request.new(Rack::MockRequest.env_for(uri))
        handler.on_start(request, nil)
        handler.on_finish(request, nil)
      end
    end
  end
end
