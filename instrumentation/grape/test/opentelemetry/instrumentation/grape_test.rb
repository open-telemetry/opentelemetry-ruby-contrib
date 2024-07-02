# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/grape'

describe OpenTelemetry::Instrumentation::Grape do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Grape::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:config) { {} }

  before do
    # Simulate fresh install
    uninstall_and_cleanup
    instrumentation.install(config)
  end

  describe '#endpoint' do
    describe 'when a basic API endpoint receives a request' do
      class BasicAPI < Grape::API
        format :json
        get :hello do
          { message: 'Hello, world!' }
        end
      end

      let(:app) { build_rack_app(BasicAPI) }
      let(:request_path) { '/hello' }
      let(:expected_span_name) { 'HTTP GET /hello' }

      before { app.get request_path }

      it 'produces a Rack span with the expected name and attributes' do
        _(spans.length).must_equal 1

        _(span.instrumentation_scope.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
        _(span.name).must_equal expected_span_name
        _(span.attributes['code.namespace']).must_equal 'BasicAPI'
        _(span.attributes['http.route']).must_equal '/hello'
      end

      it 'adds an endpoint_run span event with the expected attributes' do
        run_events = events_per_name('grape.endpoint_run')

        _(run_events.length).must_equal 1
        _(run_events.first.attributes).must_be_empty
      end

      it 'adds an endpoint_render span event with the expected attributes' do
        render_events = events_per_name('grape.endpoint_render')

        _(render_events.length).must_equal 1
        _(render_events.first.attributes).must_be_empty
      end

      it 'does not add an endpoint_run_filters span' do
        filter_events = events_per_name('grape.endpoint_run_filters')

        _(filter_events.length).must_equal 0
      end

      it 'adds a format_response span event with the expected attributes' do
        format_events = events_per_name('grape.format_response')

        _(format_events.length).must_equal 1
        _(format_events.first.attributes['grape.formatter.type']).must_equal 'json'
      end
    end

    describe 'when an API endpoint with a route param receives a request' do
      class RouteParamAPI < Grape::API
        format :json
        params do
          requires :id, type: Integer, desc: 'User ID'
        end
        get 'users/:id' do
          { id: params[:id], name: 'John Doe', email: 'johndoe@example.com' }
        end
      end

      let(:app) { build_rack_app(RouteParamAPI) }
      let(:request_path) { '/users/1' }
      let(:expected_span_name) { 'HTTP GET /users/:id' }

      before { app.get request_path }

      it 'sets the correct span name and adds the correct path attribute to the Rack span' do
        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal '/users/:id'
      end
    end

    describe 'when an API endpoint with version and prefix receives a request' do
      class VersionedWithPrefixAPI < Grape::API
        prefix :api
        version 'v1'
        get :hello do
          { message: 'Hello, world!' }
        end
      end

      let(:app) { build_rack_app(VersionedWithPrefixAPI) }
      let(:request_path) { '/api/v1/hello' }
      let(:expected_span_name) { 'HTTP GET /api/v1/hello' }

      before { app.get request_path }

      it 'sets the correct span name and adds the correct path attribute to the Rack span' do
        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal '/api/v1/hello'
      end
    end

    describe 'when an API endpoint nested in a namespace receives a request' do
      class NestedAPI < Grape::API
        format :json
        namespace :internal do
          resource :users do
            get do
              { users: ['John Doe', 'Jane Doe'] }
            end
          end
        end
      end

      let(:app) { build_rack_app(NestedAPI) }
      let(:request_path) { '/internal/users' }
      let(:expected_span_name) { 'HTTP GET /internal/users' }

      before { app.get request_path }

      it 'sets the correct span name and adds the correct path attribute to the Rack span' do
        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal '/internal/users'
      end
    end

    describe 'when a filtered API endpoint receives a request' do
      class FilteredAPI < Grape::API
        before { sleep(0.01) }
        after { sleep(0.01) }
        get :filtered do
          'OK'
        end
      end

      let(:app) { build_rack_app(FilteredAPI) }
      let(:request_path) { '/filtered' }
      let(:expected_span_name) { 'HTTP GET /filtered' }

      before { app.get request_path }

      it 'produces a Rack span with the expected name' do
        _(spans.length).must_equal 1
        _(span.name).must_equal expected_span_name
      end

      it 'adds two endpoint_run_filters events for before and after filters' do
        filter_events = events_per_name('grape.endpoint_run_filters')

        _(filter_events.length).must_equal 2
      end

      it 'adds the before filter event with the expected attributes' do
        event = events_per_name('grape.endpoint_run_filters').first
        expected_attributes = { 'grape.filter.type' => 'before' }

        _(event.attributes).must_equal expected_attributes
      end

      it 'adds the after filter event with the expected attributes' do
        event = events_per_name('grape.endpoint_run_filters').last
        expected_attributes = { 'grape.filter.type' => 'after' }

        _(event.attributes).must_equal expected_attributes
      end
    end

    describe 'when an API endpoint uses a custom formatter' do
      class CustomFormatterAPI < Grape::API
        format :txt
        formatter :txt, ->(object, _) { object.to_s }

        get :hello do
          { message: 'Hello, world!' }
        end
      end

      let(:app) { build_rack_app(CustomFormatterAPI) }
      let(:request_path) { '/hello' }
      let(:expected_span_name) { 'HTTP GET /hello' }

      before { app.get request_path }

      it 'produces a Rack span with the expected name' do
        _(spans.length).must_equal 1
        _(span.name).must_equal expected_span_name
      end

      it 'adds a format_response span event with the formatter type attribute set to custom' do
        format_events = events_per_name('grape.format_response')

        _(format_events.length).must_equal 1
        _(format_events.first.attributes['grape.formatter.type']).must_equal 'custom'
      end
    end

    describe 'when an API endpoint receives params that raise a validation error' do
      class ValidationErrorAPI < Grape::API
        format :json
        before { sleep(0.01) }
        params { requires :name, type: String }
        post :new do
          status 201
        end
      end

      let(:app) { build_rack_app(ValidationErrorAPI) }
      let(:request_path) { '/new' }
      let(:expected_span_name) { 'HTTP POST /new' }
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:expected_error_type) { 'Grape::Exceptions::ValidationErrors' }

      before { app.post request_path, headers: headers, params: {} }

      it 'sets span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(span.status.description).must_equal "Unhandled exception of type: #{expected_error_type}"
      end

      it 'records the exception event' do
        exception_events = events_per_name('exception')

        _(exception_events.length).must_equal 1
        _(exception_events.first.attributes['exception.type']).must_equal expected_error_type
        _(exception_events.first.attributes['exception.message']).must_equal 'name is missing'
      end

      it 'also records the filter event' do
        filter_events = events_per_name('grape.endpoint_run_filters')

        _(filter_events.length).must_equal 1
      end
    end

    describe 'when an API endpoint raises an error' do
      class RaisedErrorAPI < Grape::API
        before { sleep(0.01) }
        get :failure do
          raise StandardError, 'Oops!'
        end
      end

      let(:app) { build_rack_app(RaisedErrorAPI) }
      let(:request_path) { '/failure' }
      let(:expected_span_name) { 'HTTP GET /failure' }
      let(:expected_error_type) { 'StandardError' }

      before do
        expect { app.get request_path }.must_raise StandardError
      end

      it 'sets span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(span.status.description).must_equal expected_error_type
      end

      it 'records the exception event' do
        exception_events = events_per_name('exception')

        _(exception_events.length).must_equal 1
        _(exception_events.first.attributes['exception.type']).must_equal expected_error_type
        _(exception_events.first.attributes['exception.message']).must_equal 'Oops!'
      end

      it 'records events other than exceptions' do
        _(events_per_name('grape.endpoint_run').length).must_equal 1
        _(events_per_name('grape.endpoint_run_filters').length).must_equal 1
        _(events_per_name('grape.endpoint_render').length).must_equal 1
      end
    end

    describe 'when an API endpoint raises an error in the filters' do
      class ErrorInFilterAPI < Grape::API
        before { raise StandardError, 'Oops!' }
        get :filtered do
          'OK'
        end
      end

      let(:app) { build_rack_app(ErrorInFilterAPI) }
      let(:request_path) { '/filtered' }
      let(:expected_span_name) { 'HTTP GET /filtered' }
      let(:expected_error_type) { 'StandardError' }

      before do
        expect { app.get request_path }.must_raise StandardError
      end

      it 'records the filter event' do
        filter_events = events_per_name('grape.endpoint_run_filters')

        _(filter_events.length).must_equal 1
      end

      it 'sets span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(span.status.description).must_equal expected_error_type
      end

      it 'records the exception event' do
        exception_events = events_per_name('exception')

        _(exception_events.length).must_equal 1
        _(exception_events.first.attributes['exception.type']).must_equal expected_error_type
        _(exception_events.first.attributes['exception.message']).must_equal 'Oops!'
      end
    end

    describe 'when an API endpoint raises an error when formatting the response' do
      class ErrorInFormatterAPI < Grape::API
        format :xml
        get :bad_format do
          'Not OK'
        end
      end

      let(:app) { build_rack_app(ErrorInFormatterAPI) }
      let(:request_path) { '/bad_format' }
      let(:expected_span_name) { 'HTTP GET /bad_format' }
      let(:expected_error_type) { 'Grape::Exceptions::InvalidFormatter' }

      before { app.get request_path }

      it 'sets span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end

      it 'records the exception event' do
        exception_events = events_per_name('exception')

        _(exception_events.length).must_equal 1
        _(exception_events.first.attributes['exception.type']).must_equal expected_error_type
        _(exception_events.first.attributes['exception.message']).must_equal 'cannot convert String to xml'
      end
    end

    describe 'when an API endpoint returns an error without raising an exception' do
      class ErrorResponseAPI < Grape::API
        get :error_response do
          error!('Not found', 404)
        end
      end

      let(:app) { build_rack_app(ErrorResponseAPI) }
      let(:request_path) { '/error_response' }
      let(:expected_span_name) { 'HTTP GET /error_response' }

      before { app.get request_path }

      it 'does not set span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).wont_equal OpenTelemetry::Trace::Status::ERROR
      end
    end

    describe 'when an API endpoint returns an error with the status as a symbol' do
      class ErrorResponseAPI < Grape::API
        get :error_response do
          error!('Not found', :not_found)
        end
      end

      let(:app) { build_rack_app(ErrorResponseAPI) }
      let(:request_path) { '/error_response' }
      let(:expected_span_name) { 'HTTP GET /error_response' }

      before { app.get request_path }

      it 'does not set span status to error' do
        _(span.name).must_equal expected_span_name
        _(span.status.code).wont_equal OpenTelemetry::Trace::Status::ERROR
      end
    end

    describe 'when an API endpoint receives a request and some events are ignored in the configs' do
      class IgnoredEventAPI < Grape::API
        get :success do
          'OK'
        end
      end

      let(:config) { { ignored_events: [:endpoint_render] } }
      let(:app) { build_rack_app(IgnoredEventAPI) }
      let(:request_path) { '/success' }
      let(:expected_span_name) { 'HTTP GET /success' }

      before { app.get request_path }

      it 'produces a Rack span with the expected name' do
        _(spans.length).must_equal 1
        _(span.name).must_equal expected_span_name
      end

      it 'does not add the endpoint_render event to the span' do
        _(events_per_name('grape.endpoint_render').length).must_equal 0
      end
    end

    describe 'when install_rack is set to false' do
      class BasicAPI < Grape::API
        format :json
        get :hello do
          { message: 'Hello, world!' }
        end
      end

      let(:config) { { install_rack: false } }

      let(:app) do
        builder = Rack::Builder.app do
          run BasicAPI
        end
        Rack::MockRequest.new(builder)
      end

      let(:request_path) { '/hello' }
      let(:expected_span_name) { 'HTTP GET /hello' }

      describe 'missing rack installation' do
        it 'disables tracing' do
          app.get request_path
          _(exporter.finished_spans).must_be_empty
        end
      end

      describe 'when rack is manually installed' do
        let(:app) do
          build_rack_app(BasicAPI)
        end

        before do
          OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install
        end

        it 'creates a span' do
          app.get request_path
          _(exporter.finished_spans.first.attributes).must_equal(
            'code.namespace' => 'BasicAPI',
            'http.method' => 'GET',
            'http.host' => 'unknown',
            'http.scheme' => 'http',
            'http.target' => '/hello',
            'http.route' => '/hello',
            'http.status_code' => 200
          )
        end
      end
    end
  end
end
