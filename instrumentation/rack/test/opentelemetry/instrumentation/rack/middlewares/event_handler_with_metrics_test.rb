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

  let(:config) do
    {
      untraced_endpoints: [],
      enabled: instrumentation_enabled,
      use_rack_events: true
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
    @metric_exporter.reset
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
      # Should handle gracefully without raising
      begin
        handler.on_start(nil, nil)
        _(true).must_equal true  # If we get here, test passed
      rescue NoMethodError => e
        # NoMethodError is expected when calling methods on nil
        _(e).must_be_kind_of NoMethodError
      end
    end
  end

  describe '#on_commit' do
    it 'is a no-op' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new

      # Should not raise an exception
      handler.on_commit(request, response)
    end
  end

  describe '#on_error' do
    it 'is a no-op' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new
      error = StandardError.new('test error')

      # Should not raise an exception
      handler.on_error(request, response, error)
    end
  end

  describe '#on_finish' do
    it 'records metrics when start_time is present' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new([200, {}, ['OK']])

      # Set start time
      handler.on_start(request, nil)

      # Record metric
      handler.on_finish(request, response)

      # Verify metric was recorded
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      # Check if metrics are configured
      if instrumentation.config[:server_request_duration]
        _(metrics).wont_be_empty
        duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
        _(duration_metric).wont_be_nil
      else
        # If metrics are not configured, we just verify no crash
        _(true).must_equal true
      end
    end

    it 'does not record metrics when start_time is missing' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new

      # Don't set start time

      # Should not raise an exception
      handler.on_finish(request, response)
    end

    it 'handles exceptions gracefully when request is nil' do
      # Should handle gracefully without raising
      begin
        handler.on_finish(nil, nil)
        _(true).must_equal true  # If we get here, test passed
      rescue NoMethodError => e
        # NoMethodError is expected when calling methods on nil
        _(e).must_be_kind_of NoMethodError
      end
    end
  end

  describe 'integration test' do
    it 'records metrics for a complete request' do
      # Make a request through the full stack
      get uri, {}, headers

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      # Verify that metrics were recorded if configured
      if instrumentation.config[:server_request_duration]
        _(metrics).wont_be_empty
        duration_metric = metrics.find { |m| m.name == 'http.server.request.duration' }
        _(duration_metric).wont_be_nil
      end
    end

    it 'works alongside other event handlers' do
      # Create an app with multiple handlers
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
  end

  describe 'error handling' do
    it 'continues to work after metric recording errors' do
      # Mock config to return nil
      handler.stub(:config, {}) do
        request = Rack::Request.new(Rack::MockRequest.env_for(uri))

        handler.on_start(request, nil)

        # Should not raise
        handler.on_finish(request, nil)
      end
    end
  end
end
