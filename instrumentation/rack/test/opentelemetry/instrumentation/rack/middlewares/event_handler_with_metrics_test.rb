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

    @metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    OpenTelemetry.meter_provider.add_metric_reader(@metric_exporter)

    # simulate a fresh install:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)
  end

  after do
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

      assert_server_duration_metric(metrics[0], expected_count: 1)
    end

    it 'handles edge cases gracefully' do
      request = Rack::Request.new(Rack::MockRequest.env_for(uri))
      response = Rack::Response.new

      # Missing start_time - should not raise
      handler.on_finish(request, response)

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).must_be_empty
    end
  end

  describe 'integration tests' do
    it 'records metrics for a complete request' do
      get uri, {}, headers

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      assert_server_duration_metric(metrics[0], expected_count: 1)
    end

    it 'works alongside other event handlers' do
      other_handler_called = false
      other_handler = Class.new do
        include Rack::Events::Abstract

        define_method(:initialize) do |callback|
          @callback = callback
        end

        define_method(:on_start) do |_request, _response|
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
