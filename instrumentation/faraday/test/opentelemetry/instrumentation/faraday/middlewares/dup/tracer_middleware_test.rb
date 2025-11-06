# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../../lib/opentelemetry/instrumentation/faraday/middlewares/dup/tracer_middleware'

describe OpenTelemetry::Instrumentation::Faraday::Middlewares::Dup::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  let(:client) do
    Faraday.new('http://username:password@example.com') do |builder|
      builder.adapter(:test) do |stub|
        stub.get('/success') { |_| [200, {}, 'OK'] }
        stub.get('/failure') { |_| [500, {}, 'OK'] }
        stub.get('/not_found') { |_| [404, {}, 'OK'] }
        stub.get('/show-shared-attributes') { |_| [200, {}, OpenTelemetry::Common::HTTP::ClientContext.attributes.to_json] }
      end
    end
  end

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('dup')

    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http/dup'
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install
  end

  after do
    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'first span' do
    describe 'given a client with a base url' do
      it 'has http 200 attributes' do
        response = client.get('/success')

        _(span.name).must_equal 'GET'
        _(span.attributes['http.method']).must_equal 'GET'
        _(span.attributes['http.status_code']).must_equal 200
        _(span.attributes['http.url']).must_equal 'http://example.com/success'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.full']).must_equal 'http://example.com/success'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end

      it 'has http.status_code 404' do
        response = client.get('/not_found')

        _(span.name).must_equal 'GET'
        _(span.attributes['http.method']).must_equal 'GET'
        _(span.attributes['http.status_code']).must_equal 404
        _(span.attributes['http.url']).must_equal 'http://example.com/not_found'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['http.response.status_code']).must_equal 404
        _(span.attributes['url.full']).must_equal 'http://example.com/not_found'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end

      it 'has http.status_code 500' do
        response = client.get('/failure')

        _(span.name).must_equal 'GET'
        _(span.attributes['http.method']).must_equal 'GET'
        _(span.attributes['http.status_code']).must_equal 500
        _(span.attributes['http.url']).must_equal 'http://example.com/failure'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['http.response.status_code']).must_equal 500
        _(span.attributes['url.full']).must_equal 'http://example.com/failure'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end

      it 'handles unknown http method' do
        # Stub Faraday::Connection::METHODS to include :purge
        stub_const('Faraday::Connection::METHODS', Faraday::Connection::METHODS + [:purge])

        # Create a new client - Faraday test adapter will accept any stubbed method through method_missing
        purge_client = Faraday.new('http://example.com') do |builder|
          builder.adapter(:test) do |stub|
            # Use send to define the purge stub since the method doesn't exist yet
            stub.send(:new_stub, :purge, '/purge') { |_| [200, {}, 'OK'] }
          end
        end

        response = purge_client.run_request(:purge, '/purge', nil, nil)

        _(span.name).must_equal 'HTTP'
        # old semantic conventions
        _(span.attributes['http.method']).must_equal '_OTHER'
        _(span.attributes['http.status_code']).must_equal 200
        _(span.attributes['http.url']).must_equal 'http://example.com/purge'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
        # stable semantic conventions
        _(span.attributes['http.request.method']).must_equal '_OTHER'
        _(span.attributes['http.request.method_original']).must_equal 'purge'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.full']).must_equal 'http://example.com/purge'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end

      it 'merges http client attributes' do
        client_context_attrs = {
          'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE', 'http.request.method' => 'OVERRIDE'
        }
        response = OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
          client.get('/success')
        end

        _(span.name).must_equal 'GET'
        _(span.attributes['http.method']).must_equal 'OVERRIDE'
        _(span.attributes['http.status_code']).must_equal 200
        _(span.attributes['http.url']).must_equal 'http://example.com/success'
        _(span.attributes['net.peer.name']).must_equal 'example.com'
        _(span.attributes['test.attribute']).must_equal 'test.value'
        _(span.attributes['http.request.method']).must_equal 'OVERRIDE'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.full']).must_equal 'http://example.com/success'
        _(span.attributes['server.address']).must_equal 'example.com'
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end

      it 'ammends attributes to client context' do
        response = client.get('/show-shared-attributes')
        shared_attributes = JSON.parse(response.body)
        expected_attributes = {
          'http.method' => 'GET', 'http.url' => 'http://example.com/show-shared-attributes',
          'http.request.method' => 'GET', 'url.full' => 'http://example.com/show-shared-attributes',
          'faraday.adapter.name' => 'Faraday::Adapter::Test',
          'net.peer.name' => 'example.com',
          'server.address' => 'example.com'
        }

        _(shared_attributes).must_equal expected_attributes
      end

      it 'accepts peer service name from config' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(peer_service: 'example:faraday')

        client.get('/success')

        _(span.attributes['peer.service']).must_equal 'example:faraday'
      end

      it 'defaults to span kind client' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install

        client.get('/success')

        _(span.kind).must_equal :client
      end

      it 'allows overriding the span kind to internal' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(span_kind: :internal)

        client.get('/success')

        _(span.kind).must_equal :internal
      end

      it 'reports the name of the configured adapter' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install

        client.get('/success')

        _(span.attributes.fetch('faraday.adapter.name')).must_equal Faraday::Adapter::Test.name
      end

      it 'prioritizes context attributes over config for peer service name' do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(peer_service: 'example:faraday')

        client_context_attrs = { 'peer.service' => 'example:custom' }
        OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
          client.get('/success')
        end

        _(span.attributes['peer.service']).must_equal 'example:custom'
      end

      it 'does not leak authentication credentials' do
        client.run_request(:get, 'http://username:password@example.com/success', nil, {})

        _(span.attributes['http.url']).must_equal 'http://example.com/success'
      end
    end

    describe 'given a client without a base url' do
      let(:client) do
        Faraday.new do |builder|
          builder.adapter(:test) do |stub|
            stub.get('/success') { |_| [200, {}, 'OK'] }
          end
        end
      end

      it 'omits missing attributes' do
        response = client.get('/success')

        _(span.name).must_equal 'GET'
        _(span.attributes['http.method']).must_equal 'GET'
        _(span.attributes['http.status_code']).must_equal 200
        _(span.attributes['http.url']).must_equal 'http:/success'
        _(span.attributes).wont_include('net.peer.name')
        _(span.attributes['http.request.method']).must_equal 'GET'
        _(span.attributes['http.response.status_code']).must_equal 200
        _(span.attributes['url.full']).must_equal 'http:/success'
        _(span.attributes).wont_include('server.address')
        _(response.env.request_headers['Traceparent']).must_equal(
          "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
        )
      end
    end

    describe 'when faraday raises an error' do
      let(:client) do
        Faraday.new do |builder|
          builder.response :raise_error
          builder.adapter(:test) do |stub|
            stub.get('/not_found') { |_| [404, {}, 'NOT FOUND'] }
          end
        end
      end

      it 'adds response attributes' do
        assert_raises Faraday::Error do
          client.get('/not_found')
        end

        _(span.attributes['http.status_code']).must_equal 404
        _(span.attributes['http.response.status_code']).must_equal 404
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end
    end

    describe 'when explicitly adding the tracer middleware' do
      let(:client) do
        Faraday.new do |builder|
          builder.use :open_telemetry
        end
      end

      it 'only adds the middleware once' do
        tracers = client.builder.handlers.count(OpenTelemetry::Instrumentation::Faraday::Middlewares::Dup::TracerMiddleware)
        _(tracers).must_equal 1
      end
    end
  end
end
