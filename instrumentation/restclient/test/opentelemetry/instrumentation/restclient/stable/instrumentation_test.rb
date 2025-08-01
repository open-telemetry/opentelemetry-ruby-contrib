# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/restclient'
require_relative '../../../../../lib/opentelemetry/instrumentation/restclient/patches/old/request'

describe OpenTelemetry::Instrumentation::RestClient::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RestClient::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http'
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/failure').to_return(status: 500)

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      RestClient.get('http://username:password@example.com/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.full']).must_equal 'http://example.com/success'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      expect do
        RestClient.get('http://username:password@example.com/failure')
      end.must_raise RestClient::InternalServerError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['http.response.status_code']).must_equal 500
      _(span.attributes['url.full']).must_equal 'http://example.com/failure'
      assert_requested(
        :get,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges HTTP client context' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.request.method' => 'OVERRIDE'
      }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        RestClient.get('http://username:password@example.com/success')
      end

      _(span.attributes['http.request.method']).must_equal 'OVERRIDE'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      _(span.attributes['url.full']).must_equal 'http://example.com/success'
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      RestClient.get('http://example.com/success')
      _(span.attributes['peer.service']).must_equal 'example:faraday'
    end

    it 'prioritizes context attributes over config for peer service name' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client_context_attrs = { 'peer.service' => 'example:custom' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        RestClient.get('http://example.com/success')
      end
      _(span.attributes['peer.service']).must_equal 'example:custom'
    end

    it 'creates valid http method span attribute when method is a Symbol' do
      RestClient::Request.execute(method: :get, url: 'http://username:password@example.com/success')

      _(span.attributes['http.request.method']).must_equal 'GET'
    end
  end
end
