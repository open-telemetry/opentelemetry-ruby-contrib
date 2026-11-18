# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/http'
require_relative '../../../../../lib/opentelemetry/instrumentation/http/patches/stable/client'

describe OpenTelemetry::Instrumentation::HTTP::Patches::Stable::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:config) do
    {
      span_name_formatter: span_name_formatter
    }
  end
  let(:span_name_formatter) { nil }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    exporter.reset
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    # simulate a fresh install:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/success?hello=there').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout
    stub_request(:get, 'http://example.com/users/123').to_return(status: 200)
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe '#perform' do
    it 'traces a simple request' do
      HTTP.get('http://example.com/success')
      _(exporter.finished_spans.size).must_equal(1)
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.path']).must_equal '/success'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['url.full']).must_equal 'http://example.com'
      _(span.attributes['server.port']).must_equal 80
      _(span.attributes['url.query']).must_be_nil
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      HTTP.post('http://example.com/failure')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'POST'
      _(span.attributes['http.request.method']).must_equal 'POST'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 500
      _(span.attributes['url.path']).must_equal '/failure'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['url.full']).must_equal 'http://example.com'
      _(span.attributes['server.port']).must_equal 80
      _(span.attributes['url.query']).must_be_nil
      assert_requested(
        :post,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        HTTP.get('https://example.com/timeout')
      end.must_raise HTTP::TimeoutError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'https'
      _(span.attributes['http.response.status_code']).must_be_nil
      _(span.attributes['url.path']).must_equal '/timeout'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['url.full']).must_equal 'https://example.com'
      _(span.attributes['server.port']).must_equal 443
      _(span.attributes['url.query']).must_be_nil
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: HTTP::TimeoutError'
      )
      assert_requested(
        :get,
        'https://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges http client attributes' do
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo') do
        HTTP.get('http://example.com/success?hello=there')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.path']).must_equal '/success'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['url.full']).must_equal 'http://example.com'
      _(span.attributes['server.port']).must_equal 80
      _(span.attributes['url.query']).must_equal 'hello=there'
      assert_requested(
        :get,
        'http://example.com/success?hello=there',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    describe 'when span_name_formatter specified' do
      let(:span_name_formatter) do
        # demonstrate simple addition of path and string to span name:
        lambda { |request_method, request_path|
          "#{request_method} #{request_path} miniswan"
        }
      end

      it 'enriches the span' do
        OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo') do
          HTTP.get('http://example.com/success')
        end

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'GET /success miniswan'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['url.scheme']).must_equal 'http'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.path']).must_equal '/success'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(span.attributes['url.full']).must_equal 'http://example.com'
        _(span.attributes['server.port']).must_equal 80
        _(span.attributes['url.query']).must_be_nil
        assert_requested(
          :get,
          'http://example.com/success',
          headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
        )
      end
    end
    describe 'when span_formatter specified and it errors' do
      let(:span_name_formatter) do
        # demonstrate simple addition of path and string to span name:
        lambda { |_request_method, _request_path|
          raise 'Something Bad'
        }
      end

      it 'provides a sane default' do
        OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo') do
          HTTP.get('http://example.com/success')
        end

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'GET'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['url.scheme']).must_equal 'http'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.path']).must_equal '/success'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(span.attributes['url.full']).must_equal 'http://example.com'
        _(span.attributes['server.port']).must_equal 80
        _(span.attributes['url.query']).must_be_nil
        assert_requested(
          :get,
          'http://example.com/success',
          headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
        )
      end
    end

    it 'traces a request with non-standard HTTP method' do
      stub_request(:search, 'http://example.com/query').to_return(status: 200)
      HTTP.request(:search, 'http://example.com/query')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP'
      _(span.attributes['http.request.method']).must_equal '_OTHER'
      _(span.attributes['http.request.method_original']).must_equal 'search'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['url.path']).must_equal '/query'
      assert_requested(
        :search,
        'http://example.com/query',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'uses url.template in span name when present in client context' do
      client_context_attrs = { 'url.template' => '/users/{id}' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        HTTP.get('http://example.com/users/123')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET /users/{id}'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.template']).must_equal '/users/{id}'
      assert_requested(
        :get,
        'http://example.com/users/123',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end
  end

  describe 'http.client.request.duration' do
    describe 'without metrics SDK installed' do
      before { skip if defined?(OpenTelemetry::SDK::Metrics) }

      it 'completes the request and records the span without recording metrics' do
        HTTP.get('http://example.com/success')

        _(instrumentation.client_request_duration_histogram.enabled?).must_equal false
        _(exporter.finished_spans.size).must_equal 1
        _(span.attributes['http.response.status_code']).must_equal 200
      end
    end

    describe 'with metrics SDK installed' do
      let(:metric_exporter) { METRIC_EXPORTER }

      before do
        skip unless defined?(OpenTelemetry::SDK::Metrics)

        metric_exporter.pull
        metric_exporter.reset
      end

      def duration_metric
        metric_exporter.pull
        metric_exporter.metric_snapshots.find { |m| m.name == 'http.client.request.duration' }
      end

      def duration_data_points
        duration_metric&.data_points || []
      end

      it 'records a successful request' do
        HTTP.get('http://example.com/success')

        metric = duration_metric
        _(metric.unit).must_equal 's'
        _(metric.description).must_equal 'Duration of HTTP client requests.'
        _(metric.instrument_kind).must_equal :histogram
        _(metric.data_points.size).must_equal 1

        data_point = metric.data_points.first
        _(data_point.count).must_equal 1
        _(data_point.attributes).must_equal(
          'http.request.method' => 'GET',
          'server.address' => 'example.com',
          'server.port' => 80,
          'http.response.status_code' => 200,
          'network.protocol.version' => '1.1'
        )
      end

      it 'records a duration no longer than the span duration' do
        HTTP.get('http://example.com/success')

        span_duration = (span.end_timestamp - span.start_timestamp) / 1_000_000_000.0
        data_point = duration_data_points.first
        _(data_point.sum).must_be :>, 0
        _(data_point.sum).must_be :<=, span_duration
      end

      it 'records error.type for an error status code' do
        HTTP.post('http://example.com/failure')

        attributes = duration_data_points.first.attributes
        _(attributes['http.request.method']).must_equal 'POST'
        _(attributes['http.response.status_code']).must_equal 500
        _(attributes['error.type']).must_equal '500'
      end

      it 'records error.type for an exception' do
        expect do
          HTTP.get('https://example.com/timeout')
        end.must_raise HTTP::TimeoutError

        _(duration_data_points.first.attributes).must_equal(
          'http.request.method' => 'GET',
          'server.address' => 'example.com',
          'server.port' => 443,
          'error.type' => 'HTTP::TimeoutError'
        )
      end

      it 'records _OTHER for an unknown http method' do
        stub_request(:purge, 'http://example.com/purge').to_return(status: 200)

        HTTP.request(:purge, 'http://example.com/purge')

        attributes = duration_data_points.first.attributes
        _(attributes['http.request.method']).must_equal '_OTHER'
        _(attributes.key?('http.request.method_original')).must_equal false
      end

      it 'does not record span-only or client context attributes' do
        client_context_attrs = { 'peer.service' => 'foo', 'url.template' => '/users/{id}' }
        OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
          HTTP.get('http://example.com/success?hello=there')
        end

        _(duration_data_points.first.attributes.keys).must_equal(
          %w[http.request.method server.address server.port http.response.status_code network.protocol.version]
        )
      end
    end
  end
end
