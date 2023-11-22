# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/net/http'
require_relative '../../../../../lib/opentelemetry/instrumentation/net/http/patches/instrumentation'

describe OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout

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
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 80
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      Net::HTTP.post(URI('http://example.com/failure'), 'q' => 'ruby')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP POST'
      _(span.attributes['http.method']).must_equal 'POST'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.target']).must_equal '/failure'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 80
      assert_requested(
        :post,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        Net::HTTP.get(URI('https://example.com/timeout'))
      end.must_raise Net::OpenTimeout

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'https'
      _(span.attributes['http.status_code']).must_be_nil
      _(span.attributes['http.target']).must_equal '/timeout'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 443
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
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo', 'http.target' => 'REDACTED') do
        Net::HTTP.get('example.com', '/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal 'REDACTED'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['net.peer.port']).must_equal 80
      _(span.attributes['peer.service']).must_equal 'foo'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
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
        uri = URI.parse('http://bazqux.com')
        http = Net::HTTP.new(uri.host, uri.port)
        http.send(:connect)
        http.send(:do_finish)
        _(exporter.finished_spans.size).must_equal 0
      end

      it 'creates a span for a non-ignored request' do
        Net::HTTP.get('example.com', '/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
      end

      it 'creates a span on connect for a non-ignored request' do
        uri = URI.parse('http://example.com')
        http = Net::HTTP.new(uri.host, uri.port)
        http.send(:connect)
        http.send(:do_finish)
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal('connect')
        _(span.kind).must_equal(:internal)
        _(span.attributes['net.peer.name']).must_equal('example.com')
        _(span.attributes['net.peer.port']).must_equal(80)
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
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).wont_be_nil
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
      _(span.attributes['net.peer.name']).must_equal('invalid.com')
      _(span.attributes['net.peer.port']).must_equal(99_999)

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

      # rubocop:disable Lint/SuppressedException
      begin
        Net::HTTP.start(uri.host, uri.port, proxy_uri.host, proxy_uri.port, 'proxy_user', 'proxy_pass', use_ssl: true) do |http|
          http.get('/')
        end
      rescue StandardError
      end
      # rubocop:enable Lint/SuppressedException

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'HTTP CONNECT'
      _(span.kind).must_equal(:client)
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).must_equal(443)
    ensure
      WebMock.disable_net_connect!
    end

    it 'emits a "connect" span when connecting through an non-ssl proxy' do
      WebMock.allow_net_connect!

      uri = URI.parse('http://localhost')
      proxy_uri = URI.parse('https://localhost')

      # rubocop:disable Lint/SuppressedException
      begin
        Net::HTTP.start(uri.host, uri.port, proxy_uri.host, proxy_uri.port, 'proxy_user', 'proxy_pass', use_ssl: false) do |http|
          http.get('/')
        end
      rescue StandardError
      end
      # rubocop:enable Lint/SuppressedException

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'connect'
      _(span.kind).must_equal(:internal)
      _(span.attributes['net.peer.name']).must_equal('localhost')
      _(span.attributes['net.peer.port']).must_equal(443)
    ensure
      WebMock.disable_net_connect!
    end
  end
end
