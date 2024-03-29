# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../lib/opentelemetry/instrumentation/httpx'
require_relative '../../lib/opentelemetry/instrumentation/httpx/plugin'

describe OpenTelemetry::Instrumentation::HTTPX::Plugin do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTPX::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'http://example.com/timeout').to_timeout
  end

  # Force re-install of instrumentation
  after { instrumentation.instance_variable_set(:@installed, false) }

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      HTTPX.get('http://example.com/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.target']).must_equal '/success'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      HTTPX.get('http://example.com/failure')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.target']).must_equal '/failure'
      assert_requested(
        :get,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      response = HTTPX.get('http://example.com/timeout')
      assert response.is_a?(HTTPX::ErrorResponse)
      assert response.error.is_a?(HTTPX::TimeoutError)

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.target']).must_equal '/timeout'
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: HTTPX::TimeoutError'
      )
      assert_requested(
        :get,
        'http://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges HTTP client context' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE'
      }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        HTTPX.get('http://example.com/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'OVERRIDE'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:httpx')

      HTTPX.get('http://example.com/success')

      _(span.attributes['peer.service']).must_equal 'example:httpx'
    end

    it 'prioritizes context attributes over config for peer service name' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:static')

      client_context_attrs = { 'peer.service' => 'example:custom' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        HTTPX.get('http://example.com/success')
      end

      _(span.attributes['peer.service']).must_equal 'example:custom'
    end
  end
end
