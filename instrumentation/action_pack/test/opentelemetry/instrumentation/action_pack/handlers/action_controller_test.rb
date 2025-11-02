# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/action_pack'
require_relative '../../../../../lib/opentelemetry/instrumentation/action_pack/handlers'

describe OpenTelemetry::Instrumentation::ActionPack::Handlers::ActionController do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }
  let(:rails_app) { AppConfig.initialize_app }
  let(:config) { {} }

  # Clear captured spans
  before do
    OpenTelemetry::Instrumentation::ActionPack::Handlers.unsubscribe

    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)

    exporter.reset
  end

  it 'sets the span name to the format: ControllerName#action' do
    get '/ok'

    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/ok'
    _(span.attributes['http.status_code']).must_equal 200
    _(span.attributes['http.user_agent']).must_be_nil
    _(span.attributes['code.namespace']).must_equal 'ExampleController'
    _(span.attributes['code.function']).must_equal 'ok'
  end

  it 'handles action name as a symbol when setting code.function' do
    get 'ok-symbol'

    _(span.attributes['code.function']).must_equal 'ok'
  end

  it 'strips (:format) from http.route' do
    get 'items/1234'

    _(span.attributes['http.route']).must_equal '/items/:id'
  end

  it 'does not memoize data across requests' do
    get '/ok'
    get '/items/new'

    _(last_response.body).must_equal 'created new item'
    _(last_response.ok?).must_equal true
    _(span.name).must_match(/^GET/)
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/items/new'
    _(span.attributes['http.status_code']).must_equal 200
    _(span.attributes['http.user_agent']).must_be_nil
    _(span.attributes['code.namespace']).must_equal 'ExampleController'
    _(span.attributes['code.function']).must_equal 'new_item'
  end

  describe 'when encountering server side errors' do
    it 'sets semconv attributes' do
      get 'internal_server_error'

      _(span.kind).must_equal :server
      _(span.status.ok?).must_equal false

      _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
      _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.host']).must_equal 'example.org'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/internal_server_error'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.user_agent']).must_be_nil
      _(span.attributes['code.namespace']).must_equal 'ExampleController'
      _(span.attributes['code.function']).must_equal 'internal_server_error'
    end
  end

  it 'does not set the span name when an exception is raised in middleware' do
    get '/ok?raise_in_middleware'

    _(span.name).must_equal 'HTTP GET'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal false

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/ok?raise_in_middleware'
    _(span.attributes['http.status_code']).must_equal 500
    _(span.attributes['http.user_agent']).must_be_nil
    _(span.attributes['code.namespace']).must_be_nil
    _(span.attributes['code.function']).must_be_nil
  end

  it 'does not set the span name when the request is redirected in middleware' do
    get '/ok?redirect_in_middleware'

    _(span.name).must_equal 'HTTP GET'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/ok?redirect_in_middleware'
    _(span.attributes['http.status_code']).must_equal 307
    _(span.attributes['http.user_agent']).must_be_nil
    _(span.attributes['code.namespace']).must_be_nil
    _(span.attributes['code.function']).must_be_nil
  end

  describe 'span naming' do
    describe 'when using the default span_naming configuration' do
      describe 'successful requests' do
        it 'uses the Rails route' do
          get '/ok'

          _(span.name).must_equal 'GET /ok'
        end

        it 'includes route params' do
          get '/items/1234'

          _(span.name).must_equal 'GET /items/:id'
        end
      end

      describe 'server errors' do
        it 'uses the Rails route for server side errors' do
          get 'internal_server_error'

          _(span.name).must_equal 'GET /internal_server_error'
        end
      end
    end

    describe 'when using the class span_naming' do
      let(:config) { { span_naming: :class } }

      it 'uses the http method and controller name' do
        get '/ok'

        _(span.name).must_equal 'ExampleController#ok'
      end
    end
  end

  describe 'when the application has exceptions_app configured' do
    let(:rails_app) { AppConfig.initialize_app(use_exceptions_app: true) }
    let(:config) { { span_naming: :class } }

    it 'does not overwrite the span name from the controller that raised' do
      get 'internal_server_error'

      _(span.name).must_equal 'ExampleController#internal_server_error'
      _(span.kind).must_equal :server
      _(span.status.ok?).must_equal false

      _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
      _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.host']).must_equal 'example.org'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/internal_server_error'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.user_agent']).must_be_nil
      _(span.attributes['code.namespace']).must_equal 'ExceptionsController'
      _(span.attributes['code.function']).must_equal 'show'
    end

    it 'does not raise with api/non recording spans' do
      with_sampler(OpenTelemetry::SDK::Trace::Samplers::ALWAYS_OFF) do
        get 'internal_server_error'
      end
    end
  end

  it 'sets filters `http.target`' do
    get '/ok?param_to_be_filtered=bar&unfiltered_param=baz', {}
    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true
    _(span.attributes['http.target']).must_equal '/ok?param_to_be_filtered=[FILTERED]&unfiltered_param=baz'
  end

  describe 'when the application does not have the tracing rack middleware' do
    let(:rails_app) { AppConfig.initialize_app(remove_rack_tracer_middleware: true) }

    it 'does something' do
      get '/ok'

      _(last_response.body).must_equal 'actually ok'
      _(last_response.ok?).must_equal true
      _(spans.size).must_equal(0)
    end
  end

  def app
    rails_app
  end
end
