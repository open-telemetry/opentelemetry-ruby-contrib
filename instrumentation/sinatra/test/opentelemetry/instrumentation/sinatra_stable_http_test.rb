# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Sinatra do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Sinatra::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:config) { {} }

  class CustomError < StandardError; end

  let(:app_one) do
    Class.new(Sinatra::Application) do
      set :raise_errors, false
      get '/endpoint' do
        '1'
      end

      get '/error' do
        raise CustomError, 'custom message'
      end

      template :foo_template do
        'Foo Template'
      end

      get '/with_template' do
        erb :foo_template
      end

      get '/api/v1/foo/:myname/?' do
        'Some name'
      end
    end
  end

  let(:app_two) do
    Class.new(Sinatra::Application) do
      set :raise_errors, false
      get '/endpoint' do
        '2'
      end
    end
  end

  let(:apps) do
    {
      '/one' => app_one,
      '/two' => app_two
    }
  end

  let(:app) do
    apps_to_build = apps

    Rack::Builder.new do
      apps_to_build.each do |root, app|
        map root do
          run app
        end
      end
    end.to_app
  end

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')
    ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http'

    Sinatra::Base.reset!

    OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.instance_variable_set(:@installed, false)
    OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.config.clear

    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.config.clear
    instrumentation.install(config)
    exporter.reset
  end

  describe 'tracing' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      get '/one/endpoint'

      _(exporter.finished_spans.size).must_equal 1
    end

    it 'traces all apps' do
      get '/two/endpoint'

      _(exporter.finished_spans.size).must_equal 1
    end

    it 'records attributes' do
      get '/one/endpoint'

      _(exporter.finished_spans.first.attributes).must_equal(
        'server.address' => 'example.org',
        'http.request.method' => 'GET',
        'http.route' => '/endpoint',
        'url.scheme' => 'http',
        'http.response.status_code' => 200,
        'url.path' => '/endpoint'
      )
    end

    it 'traces templates' do
      get '/one/with_template'

      _(exporter.finished_spans.size).must_equal 3
      _(exporter.finished_spans.map(&:name))
        .must_equal [
          'sinatra.render_template',
          'sinatra.render_template',
          'GET /with_template'
        ]
      _(exporter.finished_spans[0..1].map(&:attributes)
        .map { |h| h['sinatra.template_name'] })
        .must_equal %w[layout foo_template]
    end

    it 'correctly name spans' do
      get '/one//api/v1/foo/janedoe/'

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.first.attributes).must_equal(
        'server.address' => 'example.org',
        'http.request.method' => 'GET',
        'url.path' => '/api/v1/foo/janedoe/',
        'url.scheme' => 'http',
        'http.response.status_code' => 200,
        'http.route' => '/api/v1/foo/:myname/?'
      )
      _(exporter.finished_spans.map(&:name))
        .must_equal [
          'GET /api/v1/foo/:myname/?'
        ]
    end

    it 'does not create unhandled exceptions for missing routes' do
      get '/one/missing_example/not_present'

      _(exporter.finished_spans.first.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      _(exporter.finished_spans.first.attributes).must_equal(
        'server.address' => 'example.org',
        'http.request.method' => 'GET',
        'url.scheme' => 'http',
        'http.response.status_code' => 404,
        'url.path' => '/missing_example/not_present'
      )
      _(exporter.finished_spans.flat_map(&:events)).must_equal([nil])
    end

    it 'does correctly name spans and add attributes and exception events when the app raises errors' do
      get '/one/error'

      _(exporter.finished_spans.first.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(exporter.finished_spans.first.name).must_equal('GET /error')
      _(exporter.finished_spans.first.attributes).must_equal(
        'server.address' => 'example.org',
        'http.request.method' => 'GET',
        'http.route' => '/error',
        'url.scheme' => 'http',
        'url.path' => '/error',
        'http.response.status_code' => 500
      )
      _(exporter.finished_spans.flat_map(&:events).map(&:name)).must_equal(['exception'])
    end

    it 'adds exception type to events when the app raises errors' do
      get '/one/error'

      _(exporter.finished_spans.first.events[0].attributes['exception.type']).must_equal('CustomError')
      _(exporter.finished_spans.first.events[0].attributes['exception.message']).must_equal('custom message')
    end
  end

  describe 'when install_rack is set to false' do
    let(:config) { { install_rack: false } }

    describe 'missing rack installation' do
      it 'disables tracing' do
        get '/one/endpoint'

        _(exporter.finished_spans).must_be_empty
      end
    end

    describe 'when rack is manually installed' do
      let(:app) do
        apps_to_build = apps
        Rack::Builder.new do
          use(*OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args)

          apps_to_build.each do |root, app|
            map root do
              run app
            end
          end
        end.to_app
      end

      before do
        OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install
      end

      it 'creates a span' do
        get '/one/endpoint'

        _(exporter.finished_spans.first.attributes).must_equal(
          'http.request.method' => 'GET',
          'server.address' => 'example.org',
          'url.scheme' => 'http',
          'url.path' => '/one/endpoint',
          'http.route' => '/endpoint',
          'http.response.status_code' => 200
        )
      end
    end
  end
end
