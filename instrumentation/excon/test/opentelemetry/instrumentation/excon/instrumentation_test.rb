# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/excon'
require_relative '../../../../lib/opentelemetry/instrumentation/excon/middlewares/tracer_middleware'
require_relative '../../../../lib/opentelemetry/instrumentation/excon/patches/socket'

describe OpenTelemetry::Instrumentation::Excon::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Excon::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'http://example.com/timeout').to_timeout

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
      _(exporter.finished_spans).must_be_empty
    end

    it 'after request with success code' do
      Excon.get('http://example.com/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    specify 'after request with capital-letters HTTP method' do
      Excon.new('http://example.com/success').request(method: 'GET')

      _(span.attributes['http.method']).must_equal 'GET'
    end

    it 'after request with failure code' do
      Excon.get('http://example.com/failure')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.target']).must_equal '/failure'
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      assert_requested(
        :get,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        Excon.get('http://example.com/timeout')
      end.must_raise Excon::Error::Timeout

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/timeout'
      _(span.attributes['http.url']).must_equal 'http://example.com/timeout'
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal('Request has failed')
      assert_requested(
        :get,
        'http://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )

      exception_event = span.events.first
      _(exception_event.attributes['exception.type']).must_equal('Excon::Error::Timeout')
      _(exception_event.attributes['exception.message']).must_equal('Excon::Error::Timeout')
    end

    it 'merges HTTP client context' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE'
      }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        Excon.get('http://example.com/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.method']).must_equal 'OVERRIDE'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      Excon.get('http://example.com/success')

      _(span.attributes['peer.service']).must_equal 'example:faraday'
    end

    it 'prioritizes context attributes over config for peer service name' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client_context_attrs = { 'peer.service' => 'example:custom' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        Excon.get('http://example.com/success')
      end

      _(span.attributes['peer.service']).must_equal 'example:custom'
    end
  end

  describe 'untraced?' do
    before do
      instrumentation.install(untraced_hosts: ['foobar.com', /bazqux\.com/])

      stub_request(:get, 'http://example.com/body').to_return(status: 200)
      stub_request(:get, 'http://foobar.com/body').to_return(status: 200)
      stub_request(:get, 'http://bazqux.com/body').to_return(status: 200)
    end

    it 'does not create a span when request ignored using a string' do
      Excon.get('http://foobar.com/body')
      _(exporter.finished_spans).must_be_empty
    end

    it 'does not create a span when request ignored using a regexp' do
      Excon.get('http://bazqux.com/body')
      _(exporter.finished_spans).must_be_empty
    end

    it 'does not create a span on connect when request ignored using a regexp' do
      uri = URI.parse('http://bazqux.com')

      Excon::Socket.new(hostname: uri.host, port: uri.port)

      _(exporter.finished_spans).must_be_empty
    end

    it 'creates a span for a non-ignored request' do
      Excon.get('http://example.com/body')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.host']).must_equal 'example.com'
      _(span.attributes['http.method']).must_equal 'GET'
    end

    it 'creates a span on connect for a non-ignored request' do
      uri = URI.parse('http://example.com')

      Excon::Socket.new(hostname: uri.host, port: uri.port)

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal('connect')
      _(span.kind).must_equal(:internal)
      _(span.attributes['net.peer.name']).must_equal('example.com')
      _(span.attributes['net.peer.port']).must_equal(80)
    end
  end

  # NOTE: WebMock introduces an extra HTTP request span due to the way the mocking is implemented.
  describe '#connect' do
    before do
      instrumentation.install
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect!
    end

    it 'emits span on connect' do
      port = nil

      TCPServer.open('localhost', 0) do |server|
        Thread.start do
          server.accept
        rescue IOError
          nil
        end

        port = server.addr[1]

        _(-> { Excon.get("http://localhost:#{port}/example", read_timeout: 0) }).must_raise(Excon::Error::Timeout)
      end

      _(exporter.finished_spans.size).must_equal(3)
      _(span.name).must_equal 'connect'
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).wont_be_nil
      _(span.attributes['net.peer.port']).must_equal(port)

      assert_http_spans(port: port, target: '/example', exception: 'Excon::Error::Timeout')
    end

    it 'captures errors' do
      _(-> { Excon.get('http://invalid.com:99999/example') }).must_raise

      _(exporter.finished_spans.size).must_equal(3)
      _(span.name).must_equal 'connect'
      _(span.attributes['net.peer.name']).must_equal('invalid.com')
      _(span.attributes['net.peer.port']).must_equal(99_999)

      span_event = span.events.first
      _(span_event.name).must_equal 'exception'
      # Depending on the Ruby and Excon Version this will be a SocketError, Socket::ResolutionError or Resolv::ResolvError
      _(span_event.attributes['exception.type']).must_match(/(Socket|Resolv)/)

      assert_http_spans(host: 'invalid.com', port: 99_999, target: '/example')
    end

    it '[BUG] fails to emit an HTTP CONNECT span when connecting through an SSL proxy for an HTTP service' do
      _(-> { Excon.get('http://localhost/', proxy: 'https://proxy_user:proxy_pass@localhost') }).must_raise(Excon::Error::Socket)

      _(exporter.finished_spans.size).must_equal(3)
      _(span.name).must_equal 'connect'
      _(span.kind).must_equal(:internal)
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).must_equal(443)

      assert_http_spans
    end

    it 'emits an HTTP CONNECT span when connecting through an SSL proxy' do
      _(-> { Excon.get('https://localhost/', proxy: 'https://proxy_user:proxy_pass@localhost') }).must_raise(Excon::Error::Socket)

      _(exporter.finished_spans.size).must_equal(3)
      _(span.name).must_equal 'HTTP CONNECT'
      _(span.kind).must_equal(:client)
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).must_equal(443)

      assert_http_spans(scheme: 'https')
    end

    it 'emits a "connect" span when connecting through an non-ssl proxy' do
      _(-> { Excon.get('http://localhost', proxy: 'https://proxy_user:proxy_pass@localhost') }).must_raise(Excon::Error::Socket)

      _(exporter.finished_spans.size).must_equal(3)
      _(span.name).must_equal 'connect'
      _(span.kind).must_equal(:internal)
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).must_equal(443)

      assert_http_spans(exception: 'Excon::Error::Socket')
    end

    it 'emits no spans when untraced' do
      OpenTelemetry::Common::Utilities.untraced do
        _(-> { Excon.get('http://localhost', proxy: 'https://proxy_user:proxy_pass@localhost') }).must_raise(Excon::Error::Socket)

        _(exporter.finished_spans.size).must_equal(0)
      end
    end
  end

  def assert_http_spans(scheme: 'http', host: 'localhost', port: nil, target: '/', exception: nil)
    exporter.finished_spans[1..].each do |http_span|
      _(http_span.name).must_equal 'HTTP GET'
      _(http_span.attributes['http.host']).must_equal host
      _(http_span.attributes['http.method']).must_equal 'GET'
      _(http_span.attributes['http.scheme']).must_equal scheme
      _(http_span.attributes['http.target']).must_equal target
      _(http_span.attributes['http.url']).must_equal "#{scheme}://#{host}#{port&.to_s&.prepend(':')}#{target}"
      _(http_span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )

      if exception
        exception_event = http_span.events.first
        _(exception_event.attributes['exception.type']).must_equal(exception)
      end
    end
  end
end
