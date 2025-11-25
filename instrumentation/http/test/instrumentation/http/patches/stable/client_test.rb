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

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http'
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
  end

  after do
    ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
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
  end
end
