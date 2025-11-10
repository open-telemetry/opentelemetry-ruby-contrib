# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/net/http'
require_relative '../../../../../../lib/opentelemetry/instrumentation/net/http/patches/stable/instrumentation'

describe OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  # let(:metric_exporter) { METRICS_EXPORTER }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    @metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    OpenTelemetry.meter_provider.add_metric_reader(@metric_exporter)

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http'
    exporter.reset

    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator

    # Install instrumentation with metrics enabled
    instrumentation.install(metrics: true, client_request_duration: true)
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.meter_provider.instance_variable_set(:@metric_readers, [])

    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'metrics integration' do
    it 'records metrics alongside spans for successful requests' do
      Net::HTTP.get('example.com', '/success')

      # Verify span was created
      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'

      # Pull and verify metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.description).must_equal 'Duration of HTTP client requests.'
      _(duration_metric.unit).must_equal 'ms'
      _(duration_metric.instrument_kind).must_equal :histogram
      _(duration_metric.instrumentation_scope.name).must_equal 'OpenTelemetry::Instrumentation::Net::HTTP'
      _(duration_metric.data_points).wont_be_empty
      _(duration_metric.data_points.first.count).must_equal 1
    end

    it 'records metrics for requests with different status codes' do
      # Test successful request
      Net::HTTP.get('example.com', '/success')

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots
      _(metrics).wont_be_empty
      _(metrics[0].data_points.first.count).must_equal 1

      # Test failed request
      Net::HTTP.post(URI('http://example.com/failure'), 'q' => 'ruby')

      _(exporter.finished_spans.last.attributes['http.response.status_code']).must_equal 500

      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots
      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.data_points).wont_be_empty
      _(duration_metric.data_points.first.count).must_equal 1
    end

    it 'records metrics even when request times out' do
      expect do
        Net::HTTP.get(URI('https://example.com/timeout'))
      end.must_raise Net::OpenTimeout

      # Verify span was created
      _(exporter.finished_spans.size).must_equal 1

      # Pull and verify metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.description).must_equal 'Duration of HTTP client requests.'
      _(duration_metric.unit).must_equal 'ms'
      _(duration_metric.instrument_kind).must_equal :histogram
      _(duration_metric.data_points).wont_be_empty
      _(duration_metric.data_points.first.count).must_equal 1
    end

    it 'records metrics for multiple requests' do
      # Make multiple requests
      3.times do
        Net::HTTP.get('example.com', '/success')
      end

      # Pull and verify metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      _(exporter.finished_spans.size).must_equal 3

      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.description).must_equal 'Duration of HTTP client requests.'
      _(duration_metric.unit).must_equal 'ms'
      _(duration_metric.instrument_kind).must_equal :histogram
      _(duration_metric.data_points).wont_be_empty
      _(duration_metric.data_points.first.count).must_equal 3
    end

    it 'does not record metrics in untraced context' do
      OpenTelemetry::Common::Utilities.untraced do
        Net::HTTP.get('example.com', '/success')
      end

      # Pull metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      # Verify that no metrics were recorded in untraced context
      duration_metric = metrics.find { |m| m.name == 'http.client.request.duration' }
      _(duration_metric).must_be_nil
    end
  end

  describe '#initialize_metrics' do
    let(:meter_provider) { OpenTelemetry.meter_provider }
    let(:meter) { meter_provider.meter('test-meter') }

    it 'initializes client_request_duration histogram' do
      instrumentation.stub(:meter, meter) do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install
      end

      histogram = instrumentation.config[:client_request_duration]
      _(histogram).wont_be_nil
      _(histogram).must_respond_to :record
    end

    it 'does not create metrics when meter is nil' do
      instrumentation.stub(:meter, nil) do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install
      end

      _(instrumentation.config[:client_request_duration]).must_be_nil
    end
  end

  describe '#connect metrics' do
    it 'records metrics for connect operations' do
      WebMock.allow_net_connect!

      TCPServer.open('localhost', 0) do |server|
        Thread.start { server.accept }
        port = server.addr[1]

        uri = URI.parse("http://localhost:#{port}/example")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 0

        # This will connect and timeout on read
        _(-> { http.request(Net::HTTP::Get.new(uri.request_uri)) }).must_raise(Net::ReadTimeout)
      end

      # Pull and verify metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.description).must_equal 'Duration of HTTP client requests.'
      _(duration_metric.unit).must_equal 'ms'
      _(duration_metric.instrument_kind).must_equal :histogram
      _(duration_metric.data_points).wont_be_empty
    ensure
      WebMock.disable_net_connect!
    end
  end

  describe 'error handling' do
    it 'continues to work after metric recording errors' do
      # Mock the instrumentation instance to return nil config
      Net::HTTP.class_eval do
        alias_method :original_record_metric, :record_metric

        define_method(:record_metric) do |_duration_ms|
          # Simulate an error in metric recording
          raise StandardError, 'Metric recording error'
        end
      end

      # This should not raise an exception
      Net::HTTP.get('example.com', '/success')

      # Restore original method
      Net::HTTP.class_eval do
        alias_method :record_metric, :original_record_metric
        remove_method :original_record_metric
      end

      # If we get here without an exception, the test passes
      _(true).must_equal true
    end
  end

  describe 'untraced_hosts configuration' do
    before do
      stub_request(:get, 'http://ignored.com/body').to_return(status: 200)
      stub_request(:get, 'http://tracked.com/body').to_return(status: 200)

      instrumentation.instance_variable_set(:@installed, false)
      config = {
        metrics: true,
        client_request_duration: true,
        untraced_hosts: ['ignored.com']
      }
      instrumentation.install(config)
    end

    it 'does not record metrics for ignored hosts' do
      Net::HTTP.get('ignored.com', '/body')

      # Pull metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      # Verify no metrics recorded for ignored host
      duration_metric = metrics.find { |m| m.name == 'http.client.request.duration' }
      _(duration_metric).must_be_nil
    end

    it 'records metrics for non-ignored hosts' do
      Net::HTTP.get('tracked.com', '/body')

      # Pull and verify metrics
      @metric_exporter.pull
      metrics = @metric_exporter.metric_snapshots

      _(metrics).wont_be_empty
      duration_metric = metrics[0]

      _(duration_metric).wont_be_nil
      _(duration_metric.name).must_equal 'http.client.request.duration'
      _(duration_metric.description).must_equal 'Duration of HTTP client requests.'
      _(duration_metric.unit).must_equal 'ms'
      _(duration_metric.instrument_kind).must_equal :histogram
      _(duration_metric.data_points).wont_be_empty
      _(duration_metric.data_points.first.count).must_equal 1
    end
  end
end
