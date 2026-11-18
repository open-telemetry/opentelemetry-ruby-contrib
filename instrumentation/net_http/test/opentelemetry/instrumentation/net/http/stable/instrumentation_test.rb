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

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/success?hello=there').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout
    stub_request(:get, 'http://example.com/users/123').to_return(status: 200)

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe '#request' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      Net::HTTP.get('example.com', '/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.path']).must_equal '/success'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['server.port']).must_equal 80
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      Net::HTTP.post(URI('http://example.com/failure'), 'q' => 'ruby')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'POST'
      _(span.attributes['http.request.method']).must_equal 'POST'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 500
      _(span.attributes['url.path']).must_equal '/failure'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['server.port']).must_equal 80
      assert_requested(
        :post,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with unknown http method' do
      stub_request(:purge, 'http://example.com/purge').to_return(status: 200)

      uri = URI('http://example.com/purge')
      request = Net::HTTP::Purge.new(uri)

      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP'
      _(span.attributes['http.request.method']).must_equal '_OTHER'
      _(span.attributes['http.request.method_original']).must_equal 'PURGE'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.path']).must_equal '/purge'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['server.port']).must_equal 80
      assert_requested(
        :purge,
        'http://example.com/purge',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        Net::HTTP.get(URI('https://example.com/timeout'))
      end.must_raise Net::OpenTimeout

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'https'
      _(span.attributes['http.response.status_code']).must_be_nil
      _(span.attributes['url.path']).must_equal '/timeout'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['server.port']).must_equal 443
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: Net::OpenTimeout'
      )
      assert_requested(
        :get,
        'https://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges http client attributes' do
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo', 'url.path' => 'REDACTED') do
        Net::HTTP.get('example.com', '/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['http.request.method']).must_equal 'GET'
      _(span.attributes['url.scheme']).must_equal 'http'
      _(span.attributes['http.response.status_code']).must_equal 200
      _(span.attributes['url.path']).must_equal 'REDACTED'
      _(span.attributes['server.address']).must_equal 'example.com'
      _(span.attributes['server.port']).must_equal 80
      _(span.attributes['peer.service']).must_equal 'foo'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges http client attribute url query' do
      Net::HTTP.get('example.com', '/success?hello=there')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'GET'
      _(span.attributes['url.query']).must_equal 'hello=there'
      _(span.attributes['url.path']).must_equal '/success'
      assert_requested(
        :get,
        'http://example.com/success?hello=there',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'handles URI-like request paths' do
      path = Class.new do
        def empty? = false
        def request_uri = '/success?hello=there'
      end.new
      request = Net::HTTP::Get.new(path)

      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.split_path_and_query(request.path)).must_equal ['/success', 'hello=there']
    end

    it 'handles URI-like paths without an HTTP request URI' do
      path = Class.new do
        def empty? = false
        def request_uri = nil
      end.new
      request = Net::HTTP::Get.new(path)
      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.split_path_and_query(request.path)).must_equal [nil, nil]
    end
  end

  describe 'untraced?' do
    before do
      stub_request(:get, 'http://example.com/body').to_return(status: 200)
      stub_request(:get, 'http://foobar.com/body').to_return(status: 200)
      stub_request(:get, 'http://bazqux.com/body').to_return(status: 200)
    end

    describe 'untraced_hosts option' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        config = {
          untraced_hosts: ['foobar.com', /bazqux\.com/]
        }

        instrumentation.install(config)
      end

      it 'does not create a span when request ignored using a string' do
        Net::HTTP.get('foobar.com', '/body')
        _(exporter.finished_spans.size).must_equal 0
      end

      it 'does not create a span when request ignored using a regexp' do
        Net::HTTP.get('bazqux.com', '/body')
        _(exporter.finished_spans.size).must_equal 0
      end

      it 'does not create a span on connect when request ignored using a regexp' do
        # this works because http://bazqux.com is reachable site; try http://asdfasdfsef.com will fail
        uri = URI.parse('http://bazqux.com')
        http = Net::HTTP.new(uri.host, uri.port)
        http.send(:connect)
        http.send(:do_finish)
        _(exporter.finished_spans.size).must_equal 0
      end

      it 'creates a span for a non-ignored request' do
        Net::HTTP.get('example.com', '/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'GET'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['server.address']).must_equal 'example.com'
      end

      it 'creates a span on connect for a non-ignored request' do
        uri = URI.parse('http://example.com')
        http = Net::HTTP.new(uri.host, uri.port)

        fake_socket = Object.new
        def fake_socket.setsockopt(*args); end
        def fake_socket.close; end

        # Replace the TCP socket creation with our fake socket
        allow(TCPSocket).to receive(:open).and_return(fake_socket)
        http.send(:connect)

        http.send(:do_finish)
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal('connect')
        _(span.kind).must_equal(:internal)
        _(span.attributes['server.address']).must_equal('example.com')
        _(span.attributes['server.port']).must_equal(80)
      end
    end

    describe 'untraced context' do
      it 'no-ops on #request' do
        # Calling `tracer.in_span` within an untraced context causes the logging of "called
        # finish on an ended Span" messages. To avoid log noise, the instrumentation must
        # no-op (i.e., not call `tracer.in_span`) when the context is untraced.
        expect(instrumentation.tracer).not_to receive(:in_span)

        OpenTelemetry::Common::Utilities.untraced do
          Net::HTTP.get('example.com', '/body')
        end

        _(exporter.finished_spans.size).must_equal 0
      end

      it 'no-ops on #connect' do
        expect(instrumentation.tracer).not_to receive(:in_span)

        OpenTelemetry::Common::Utilities.untraced do
          uri = URI.parse('http://example.com/body')
          http = Net::HTTP.new(uri.host, uri.port)

          # Mock the connect
          http.define_singleton_method(:connect) { true }

          http.send(:connect)
          http.send(:do_finish)
        end

        _(exporter.finished_spans.size).must_equal 0
      end
    end
  end

  describe '#connect' do
    it 'emits span on connect' do
      WebMock.allow_net_connect!
      TCPServer.open('localhost', 0) do |server|
        Thread.start { server.accept }
        port = server.addr[1]

        uri  = URI.parse("http://localhost:#{port}/example")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 0
        _(-> { http.request(Net::HTTP::Get.new(uri.request_uri)) }).must_raise(Net::ReadTimeout)
      end

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'connect'
      _(span.attributes['server.address']).must_equal('localhost')
      _(span.attributes['server.port']).wont_be_nil
    ensure
      WebMock.disable_net_connect!
    end

    it 'captures errors' do
      WebMock.allow_net_connect!

      uri  = URI.parse('http://invalid.com:99999/example')
      http = Net::HTTP.new(uri.host, uri.port)
      _(-> { http.request(Net::HTTP::Get.new(uri.request_uri)) }).must_raise

      _(exporter.finished_spans.size).must_equal(1)
      _(span.name).must_equal 'connect'
      _(span.attributes['server.address']).must_equal('invalid.com')
      _(span.attributes['server.port']).must_equal(99_999)

      span_event = span.events.first

      _(span_event.name).must_equal 'exception'
      _(span_event.attributes['exception.type']).wont_be_nil
      _(span_event.attributes['exception.message']).must_match(/Failed to open TCP connection to invalid.com:99999/)
    ensure
      WebMock.disable_net_connect!
    end

    it 'emits an HTTP CONNECT span when connecting through an SSL proxy' do
      WebMock.allow_net_connect!

      uri = URI.parse('http://localhost')
      proxy_uri = URI.parse('https://localhost')

      # rubocop:disable-next Lint/SuppressedException
      begin
        Net::HTTP.start(uri.host, uri.port, proxy_uri.host, proxy_uri.port, 'proxy_user', 'proxy_pass', use_ssl: true) do |http|
          http.get('/')
        end
      rescue StandardError
      end

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'CONNECT'
      _(span.kind).must_equal(:client)
      _(span.attributes['server.address']).must_equal('localhost')
      _(span.attributes['server.port']).must_equal(443)
    ensure
      WebMock.disable_net_connect!
    end

    it 'emits a "connect" span when connecting through an non-ssl proxy' do
      WebMock.allow_net_connect!

      uri = URI.parse('http://localhost')
      proxy_uri = URI.parse('https://localhost')

      # rubocop:disable-next Lint/SuppressedException
      begin
        Net::HTTP.start(uri.host, uri.port, proxy_uri.host, proxy_uri.port, 'proxy_user', 'proxy_pass', use_ssl: false) do |http|
          http.get('/')
        end
      rescue StandardError
      end

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'connect'
      _(span.kind).must_equal(:internal)
      _(span.attributes['server.address']).must_equal('localhost')
      _(span.attributes['server.port']).must_equal(443)
    ensure
      WebMock.disable_net_connect!
    end

    it 'does not record a nil server.address' do
      fake_socket = Object.new
      def fake_socket.setsockopt(*args); end
      def fake_socket.close; end

      # Replace the TCP socket creation with our fake socket
      allow(TCPSocket).to receive(:open).and_return(fake_socket)
      Net::HTTP.new(nil, 80).send(:connect)

      _(span.name).must_equal 'connect'
      _(span.attributes.key?('server.address')).must_equal false
    end

    it 'uses url.template in span name when present in client context' do
      client_context_attrs = { 'url.template' => '/users/{id}' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        Net::HTTP.get('example.com', '/users/123')
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
        Net::HTTP.get('example.com', '/success')

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
        Net::HTTP.get('example.com', '/success')

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
          'network.protocol.version' => '1.0'
        )
      end

      it 'records a duration no longer than the span duration' do
        Net::HTTP.get('example.com', '/success')

        span_duration = (span.end_timestamp - span.start_timestamp) / 1_000_000_000.0
        data_point = duration_data_points.first
        _(data_point.sum).must_be :>, 0
        _(data_point.sum).must_be :<=, span_duration
      end

      it 'records error.type for an error status code' do
        Net::HTTP.post(URI('http://example.com/failure'), 'q' => 'ruby')

        attributes = duration_data_points.first.attributes
        _(attributes['http.request.method']).must_equal 'POST'
        _(attributes['http.response.status_code']).must_equal 500
        _(attributes['error.type']).must_equal '500'
      end

      it 'records error.type for an exception' do
        expect do
          Net::HTTP.get(URI('https://example.com/timeout'))
        end.must_raise Net::OpenTimeout

        _(duration_data_points.first.attributes).must_equal(
          'http.request.method' => 'GET',
          'server.address' => 'example.com',
          'server.port' => 443,
          'error.type' => 'Net::OpenTimeout'
        )
      end

      it 'records _OTHER for an unknown http method' do
        stub_request(:purge, 'http://example.com/purge').to_return(status: 200)

        uri = URI('http://example.com/purge')
        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(Net::HTTP::Purge.new(uri))
        end

        attributes = duration_data_points.first.attributes
        _(attributes['http.request.method']).must_equal '_OTHER'
        _(attributes.key?('http.request.method_original')).must_equal false
      end

      it 'does not record span-only or client context attributes' do
        client_context_attrs = { 'peer.service' => 'foo', 'url.template' => '/users/{id}' }
        OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
          Net::HTTP.get('example.com', '/success?hello=there')
        end

        _(duration_data_points.first.attributes.keys).must_equal(
          %w[http.request.method server.address server.port http.response.status_code network.protocol.version]
        )
      end

      it 'does not record an untraced host' do
        stub_request(:get, 'http://foobar.com/body').to_return(status: 200)
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(untraced_hosts: ['foobar.com'])

        Net::HTTP.get('foobar.com', '/body')

        _(duration_data_points).must_be_empty
      end

      it 'does not record in an untraced context' do
        OpenTelemetry::Common::Utilities.untraced do
          Net::HTTP.get('example.com', '/success')
        end

        _(duration_data_points).must_be_empty
      end
    end
  end
end
