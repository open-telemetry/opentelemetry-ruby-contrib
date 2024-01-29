# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/event_handler'

describe 'OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler' do
  include Rack::Test::Methods

  let(:instrumentation_module) { OpenTelemetry::Instrumentation::Rack }
  let(:instrumentation_class) { instrumentation_module::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }
  let(:instrumentation_enabled) { true }

  let(:config) do
    {
      untraced_endpoints: untraced_endpoints,
      untraced_requests: untraced_requests,
      allowed_request_headers: allowed_request_headers,
      allowed_response_headers: allowed_response_headers,
      url_quantization: url_quantization,
      propagate_with_link: propagate_with_link,
      response_propagators: response_propagators,
      enabled: instrumentation_enabled,
      use_rack_events: true
    }
  end

  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:rack_span) { exporter.finished_spans.first }
  let(:proxy_event) { rack_span.events&.first }
  let(:uri) { '/' }
  let(:handler) do
    OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler.new
  end

  let(:after_close) { nil }
  let(:response_body) { Rack::BodyProxy.new(['Hello World']) { after_close&.call } }

  let(:service) do
    ->(_arg) { [200, { 'Content-Type' => 'text/plain' }, response_body] }
  end
  let(:untraced_endpoints) { [] }
  let(:untraced_requests) { nil }
  let(:allowed_request_headers) { nil }
  let(:allowed_response_headers) { nil }
  let(:response_propagators) { nil }
  let(:url_quantization) { nil }
  let(:propagate_with_link) { nil }
  let(:headers) { {} }
  let(:app) do
    Rack::Builder.new.tap do |builder|
      builder.use Rack::Events, [handler]
      builder.run service
    end
  end

  before do
    exporter.reset

    # simulate a fresh install:
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)
  end

  describe '#call' do
    before do
      get uri, {}, headers
    end

    it 'record a span' do
      _(rack_span.attributes['http.method']).must_equal 'GET'
      _(rack_span.attributes['http.status_code']).must_equal 200
      _(rack_span.attributes['http.target']).must_equal '/'
      _(rack_span.attributes['http.url']).must_be_nil
      _(rack_span.name).must_equal 'HTTP GET'
      _(rack_span.kind).must_equal :server
      _(rack_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      _(rack_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(proxy_event).must_be_nil
    end

    describe 'when a query is passed in' do
      let(:uri) { '/endpoint?query=true' }

      it 'records the query path' do
        _(rack_span.attributes['http.target']).must_equal '/endpoint?query=true'
        _(rack_span.name).must_equal 'HTTP GET'
      end
    end

    describe 'config[:untraced_endpoints]' do
      describe 'when an array is passed in' do
        let(:untraced_endpoints) { ['/ping'] }

        it 'does not trace paths listed in the array' do
          get '/ping'

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/ping' }
          _(ping_span).must_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end

      describe 'when nil is passed in' do
        let(:config) { { untraced_endpoints: nil } }

        it 'traces everything' do
          get '/ping'

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/ping' }
          _(ping_span).wont_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end
    end

    describe 'config[:untraced_requests]' do
      describe 'when a callable is passed in' do
        let(:untraced_requests) do
          ->(env) { env['PATH_INFO'] =~ %r{^\/assets} }
        end

        it 'does not trace requests in which the callable returns true' do
          get '/assets'

          assets_span = finished_spans.find { |s| s.attributes['http.target'] == '/assets' }
          _(assets_span).must_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end

      describe 'when nil is passed in' do
        let(:config) { { untraced_requests: nil } }

        it 'traces everything' do
          get '/assets'

          asset_span = finished_spans.find { |s| s.attributes['http.target'] == '/assets' }
          _(asset_span).wont_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end
    end

    describe 'config[:allowed_request_headers]' do
      let(:headers) do
        Hash(
          'CONTENT_LENGTH' => '123',
          'CONTENT_TYPE' => 'application/json',
          'HTTP_FOO_BAR' => 'http foo bar value'
        )
      end

      it 'defaults to nil' do
        _(rack_span.attributes['http.request.header.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:allowed_request_headers) do
          ['foo_BAR']
        end

        it 'returns attribute' do
          _(rack_span.attributes['http.request.header.foo_bar']).must_equal 'http foo bar value'
        end
      end

      describe 'when content-type' do
        let(:allowed_request_headers) { ['CONTENT_TYPE'] }

        it 'returns attribute' do
          _(rack_span.attributes['http.request.header.content_type']).must_equal 'application/json'
        end
      end

      describe 'when content-length' do
        let(:allowed_request_headers) { ['CONTENT_LENGTH'] }

        it 'returns attribute' do
          _(rack_span.attributes['http.request.header.content_length']).must_equal '123'
        end
      end
    end

    describe 'config[:allowed_response_headers]' do
      let(:service) do
        ->(_env) { [200, { 'Foo-Bar' => 'foo bar response header' }, ['OK']] }
      end

      it 'defaults to nil' do
        _(rack_span.attributes['http.response.header.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:allowed_response_headers) { ['Foo-Bar'] }

        it 'returns attribute' do
          _(rack_span.attributes['http.response.header.foo_bar']).must_equal 'foo bar response header'
        end

        describe 'case-sensitively' do
          let(:allowed_response_headers) { ['fOO-bAR'] }

          it 'returns attribute' do
            _(rack_span.attributes['http.response.header.foo_bar']).must_equal 'foo bar response header'
          end
        end
      end
    end

    describe 'given request proxy headers' do
      let(:headers) { Hash('HTTP_X_REQUEST_START' => '1677723466') }

      it 'records an event' do
        _(proxy_event.name).must_equal 'http.proxy.request.started'
        _(proxy_event.timestamp).must_equal 1_677_723_466_000_000_000
      end
    end

    describe '#called with 400 level http status code' do
      let(:service) do
        ->(_env) { [404, { 'Foo-Bar' => 'foo bar response header' }, ['Not Found']] }
      end

      it 'leaves status code unset' do
        _(rack_span.attributes['http.status_code']).must_equal 404
        _(rack_span.kind).must_equal :server
        _(rack_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      end
    end
  end

  describe 'url quantization' do
    describe 'when using standard Rack environment variables' do
      describe 'without quantization' do
        it 'span.name defaults to low cardinality name HTTP method' do
          get '/really_long_url'

          _(rack_span.name).must_equal 'HTTP GET'
          _(rack_span.attributes['http.target']).must_equal '/really_long_url'
        end
      end

      describe 'with simple quantization' do
        let(:quantization_example) do
          ->(url, _env) { url.to_s }
        end

        let(:url_quantization) { quantization_example }

        it 'sets the span.name to the full path' do
          get '/really_long_url'

          _(rack_span.name).must_equal '/really_long_url'
          _(rack_span.attributes['http.target']).must_equal '/really_long_url'
        end
      end

      describe 'with quantization' do
        let(:quantization_example) do
          # demonstrate simple shortening of URL:
          ->(url, _env) { url.to_s[0..5] }
        end
        let(:url_quantization) { quantization_example }

        it 'mutates url according to url_quantization' do
          get '/really_long_url'

          _(rack_span.name).must_equal '/reall'
        end
      end
    end

    describe 'when using Action Dispatch custom environment variables' do
      describe 'without quantization' do
        it 'span.name defaults to low cardinality name HTTP method' do
          get '/really_long_url', {}, { 'REQUEST_URI' => '/action-dispatch-uri' }

          _(rack_span.name).must_equal 'HTTP GET'
          _(rack_span.attributes['http.target']).must_equal '/really_long_url'
        end
      end

      describe 'with simple quantization' do
        let(:quantization_example) do
          ->(url, _env) { url.to_s }
        end

        let(:url_quantization) { quantization_example }

        it 'sets the span.name to the full path' do
          get '/really_long_url', {}, { 'REQUEST_URI' => '/action-dispatch-uri' }

          _(rack_span.name).must_equal '/action-dispatch-uri'
          _(rack_span.attributes['http.target']).must_equal '/really_long_url'
        end
      end

      describe 'with quantization' do
        let(:quantization_example) do
          # demonstrate simple shortening of URL:
          ->(url, _env) { url.to_s[0..5] }
        end
        let(:url_quantization) { quantization_example }

        it 'mutates url according to url_quantization' do
          get '/really_long_url', {}, { 'REQUEST_URI' => '/action-dispatch-uri' }

          _(rack_span.name).must_equal '/actio'
        end
      end
    end
  end

  describe 'response_propagators' do
    describe 'with default options' do
      it 'does not inject the traceresponse header' do
        get '/ping'
        _(last_response.headers).wont_include('traceresponse')
      end
    end

    describe 'with ResponseTextMapPropagator' do
      let(:response_propagators) { [OpenTelemetry::Trace::Propagation::TraceContext::ResponseTextMapPropagator.new] }

      it 'injects the traceresponse header' do
        get '/ping'
        _(last_response.headers).must_include('traceresponse')
      end
    end

    describe 'response propagators that raise errors' do
      class EventMockPropagator < OpenTelemetry::Trace::Propagation::TraceContext::ResponseTextMapPropagator
        CustomError = Class.new(StandardError)
        def inject(carrier)
          raise CustomError, 'Injection failed'
        end
      end

      let(:response_propagators) { [EventMockPropagator.new, OpenTelemetry::Trace::Propagation::TraceContext::ResponseTextMapPropagator.new] }

      it 'is fault tolerant' do
        expect(OpenTelemetry).to receive(:handle_error).with(exception: instance_of(EventMockPropagator::CustomError), message: /Unable/)

        get '/ping'
        _(last_response.headers).must_include('traceresponse')
      end
    end
  end

  describe '#call with error' do
    EventHandlerError = Class.new(StandardError)

    let(:service) do
      ->(_env) { raise EventHandlerError }
    end

    it 'records error in span and then re-raises' do
      assert_raises EventHandlerError do
        get '/'
      end

      _(rack_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
    end
  end

  describe 'when the instrumentation is disabled' do
    let(:instrumenation_enabled) { false }

    it 'does nothing' do
      _(rack_span).must_be_nil
    end
  end

  describe 'when response body is called' do
    let(:after_close) { -> { OpenTelemetry::Instrumentation::Rack.current_span.add_event('after-response-called') } }

    it 'has access to a Rack read/write span' do
      get '/'
      _(rack_span.events.map(&:name)).must_include('after-response-called')
    end
  end

  describe 'when response body is called' do
    let(:response_body) { ['Simple, Hello World!'] }

    it 'has access to a Rack read/write span' do
      get '/'
      _(rack_span.attributes['http.method']).must_equal 'GET'
      _(rack_span.attributes['http.status_code']).must_equal 200
      _(rack_span.attributes['http.target']).must_equal '/'
      _(rack_span.attributes['http.url']).must_be_nil
      _(rack_span.name).must_equal 'HTTP GET'
      _(rack_span.kind).must_equal :server
      _(rack_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      _(rack_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
      _(proxy_event).must_be_nil
    end
  end

  describe 'link propagation' do
    describe 'without link propagation fn' do
      it 'the root span has no links' do
        get '/url'

        _(rack_span.name).must_equal 'HTTP GET'
        _(rack_span.total_recorded_links).must_equal(0)
      end
    end

    describe 'with link propagation fn that returns false' do
      let(:propagate_with_link) do
        ->(_env) { false }
      end

      it 'has no links' do
        get '/url'

        _(rack_span.name).must_equal 'HTTP GET'
        _(rack_span.total_recorded_links).must_equal(0)
      end
    end

    describe 'with link propagation fn that returns true' do
      let(:propagate_with_link) do
        ->(env) { env['PATH_INFO'].start_with?('/url') }
      end

      it 'has links' do
        trace_id = '618c54694e838292271da0ba122547e9'
        span_id = 'd408cc622ee29ce0'
        header 'traceparent', "00-#{trace_id}-#{span_id}-01"
        get '/url'

        _(rack_span.name).must_equal 'HTTP GET'
        _(rack_span.total_recorded_links).must_equal(1)
        _(rack_span.links[0].span_context.trace_id.unpack1('H*')).must_equal(trace_id)
        _(rack_span.links[0].span_context.span_id.unpack1('H*')).must_equal(span_id)
      end
    end
  end
end
