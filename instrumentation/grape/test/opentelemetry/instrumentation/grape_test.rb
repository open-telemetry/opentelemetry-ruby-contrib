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
  let(:run_spans) { spans_per_operation('endpoint_run') }
  let(:render_spans) { spans_per_operation('endpoint_render') }
  let(:filter_spans) { spans_per_operation('endpoint_run_filters') }
  let(:format_spans) { spans_per_operation('format_response') }
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

      let(:app) { BasicAPI }
      let(:request_path) { '/hello' }
      let(:expected_span_name) { 'GET /hello' }

      before { get request_path }

      it 'produces an endpoint_run span with the expected attributes' do
        _(run_spans.length).must_equal 1

        span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.kind).must_equal :server
        _(span.attributes['operation']).must_equal 'endpoint_run'
        _(span.attributes['grape.route.endpoint']).must_equal 'BasicAPI'
        _(span.attributes['http.route']).must_equal '/hello'
        _(span.attributes['http.method']).must_equal 'GET'
      end

      it 'produces a child endpoint_render span with the expected attributes' do
        _(render_spans.length).must_equal 1

        span = render_spans.first
        parent_span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.kind).must_equal :server
        _(span.attributes['operation']).must_equal 'endpoint_render'

        _(span.parent_span_id).must_equal parent_span.span_id
        _(span.trace_id).must_equal parent_span.trace_id
      end

      it 'does not produce a child endpoint_run_filters span' do
        _(filter_spans.length).must_equal 0
      end

      it 'produces a format_response span with the expected attributes' do
        _(format_spans.length).must_equal 1

        span = format_spans.first

        _(span.name).must_equal expected_span_name
        _(span.kind).must_equal :server
        _(span.attributes['operation']).must_equal 'format_response'
        _(span.attributes['grape.formatter.type']).must_equal 'json'
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

      let(:app) { RouteParamAPI }
      let(:request_path) { '/users/1' }
      let(:expected_span_name) { 'GET /users/:id' }
      let(:expected_path) { '/users/:id' }

      before { get request_path }

      it 'produces an endpoint_run span with the correct path attributes' do
        span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal expected_path
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

      let(:app) { VersionedWithPrefixAPI }
      let(:request_path) { '/api/v1/hello' }
      let(:expected_span_name) { 'GET /api/v1/hello' }
      let(:expected_path) { '/api/v1/hello' }

      before { get request_path }

      it 'produces an endpoint_run span with the correct path attributes' do
        span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal expected_path
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

      let(:app) { NestedAPI }
      let(:request_path) { '/internal/users' }
      let(:expected_span_name) { 'GET /internal/users' }
      let(:expected_path) { '/internal/users' }

      before { get request_path }

      it 'produces an endpoint_run span with the correct path attributes' do
        span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.attributes['http.route']).must_equal expected_path
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

      let(:app) { FilteredAPI }
      let(:request_path) { '/filtered' }
      let(:expected_span_name) { 'GET /filtered' }

      before { get request_path }

      it 'produces an endpoint_run and an endpoint_render span' do
        _(run_spans.length).must_equal 1
        _(render_spans.length).must_equal 1

        (run_spans + render_spans).each do |span|
          _(span.name).must_equal expected_span_name
        end
      end

      it 'produces two endpoint_run_filters spans for before and after filters' do
        _(filter_spans.length).must_equal 2
      end

      it 'produces the before filter span with the expected attributes and parent span' do
        span = filter_spans.first
        parent_span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.kind).must_equal :server
        _(span.attributes['operation']).must_equal 'endpoint_run_filters'
        _(span.attributes['grape.filter.type']).must_equal 'before'

        _(span.parent_span_id).must_equal parent_span.span_id
        _(span.trace_id).must_equal parent_span.trace_id
      end

      it 'produces the after filter span with the expected attributes and parent span' do
        span = filter_spans.last
        parent_span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.kind).must_equal :server
        _(span.attributes['operation']).must_equal 'endpoint_run_filters'
        _(span.attributes['grape.filter.type']).must_equal 'after'

        _(span.parent_span_id).must_equal parent_span.span_id
        _(span.trace_id).must_equal parent_span.trace_id
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

      let(:app) { ValidationErrorAPI }
      let(:request_path) { '/new' }
      let(:expected_span_name) { 'POST /new' }
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:expected_error_type) { 'Grape::Exceptions::ValidationErrors' }

      before { post request_path, headers: headers, params: {} }

      it 'sets span status to error in endpoint_render and endpoint_run spans' do
        (run_spans + render_spans).each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
          _(span.status.description).must_equal "Unhandled exception of type: #{expected_error_type}"
        end
      end

      it 'records the exception in endpoint_render and endpoint_run spans' do
        (run_spans + render_spans).each do |span|
          _(span.events.first.name).must_equal 'exception'
          _(span.events.first.attributes['exception.type']).must_equal expected_error_type
          _(span.events.first.attributes['exception.message']).must_equal 'name is missing'
        end
      end

      it 'does not set span status to error in endpoint_run_filter spans' do
        filter_spans.each do |span|
          _(span.status.code).wont_equal OpenTelemetry::Trace::Status::ERROR
        end
      end
    end

    describe 'when an API endpoint raises an error' do
      class RaisedErrorAPI < Grape::API
        before { sleep(0.01) }
        get :failure do
          raise StandardError, 'Oops!'
        end
      end

      let(:app) { RaisedErrorAPI }
      let(:request_path) { '/failure' }
      let(:expected_span_name) { 'GET /failure' }
      let(:expected_error_type) { 'StandardError' }

      before do
        expect { get request_path }.must_raise StandardError
      end

      it 'sets span status to error in endpoint_render and endpoint_run spans' do
        (run_spans + render_spans).each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
          _(span.status.description).must_equal "Unhandled exception of type: #{expected_error_type}"
        end
      end

      it 'records the exception in endpoint_render and endpoint_run spans' do
        (run_spans + render_spans).each do |span|
          _(span.events.first.name).must_equal 'exception'
          _(span.events.first.attributes['exception.type']).must_equal expected_error_type
          _(span.events.first.attributes['exception.message']).must_equal 'Oops!'
        end
      end

      it 'does not set span status to error in endpoint_run_filters spans' do
        filter_spans.each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).wont_equal OpenTelemetry::Trace::Status::ERROR
        end
      end
    end

    describe 'when an API endpoint raises an error in the filters' do
      class ErrorInFilterAPI < Grape::API
        before { raise StandardError, 'Oops!' }
        get :filtered do
          'OK'
        end
      end

      let(:app) { ErrorInFilterAPI }
      let(:request_path) { '/filtered' }
      let(:expected_span_name) { 'GET /filtered' }
      let(:expected_error_type) { 'StandardError' }

      before do
        expect { get request_path }.must_raise StandardError
      end

      it 'sets span status to error in endpoint_run_filters spans' do
        filter_spans.each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
          _(span.status.description).must_equal "Unhandled exception of type: #{expected_error_type}"
        end
      end

      it 'records the exception in endpoint_run_filters spans' do
        (run_spans + render_spans).each do |span|
          _(span.events.first.name).must_equal 'exception'
          _(span.events.first.attributes['exception.type']).must_equal expected_error_type
          _(span.events.first.attributes['exception.message']).must_equal 'Oops!'
        end
      end

      it 'produces a span for endpoint_run (with error) despite the exception in filters' do
        _(run_spans.size).must_equal 1

        span = run_spans.first

        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end
    end

    describe 'when an API endpoint raises an error when formatting the response' do
      class ErrorInFormatterAPI < Grape::API
        format :xml
        get :bad_format do
          'Not OK'
        end
      end

      let(:app) { ErrorInFormatterAPI }
      let(:request_path) { '/bad_format' }
      let(:expected_span_name) { 'GET /bad_format' }
      let(:expected_error_type) { 'Grape::Exceptions::InvalidFormatter' }

      before { get request_path }

      it 'sets format_response span status to error' do
        _(format_spans.size).must_equal 1

        span = format_spans.first

        _(span.name).must_equal expected_span_name
        _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(span.status.description).must_equal "Unhandled exception of type: #{expected_error_type}"
      end

      it 'records the exception in format_response spans' do
        span = format_spans.first

        _(span.events.first.name).must_equal 'exception'
        _(span.events.first.attributes['exception.type']).must_equal expected_error_type
        _(span.events.first.attributes['exception.message']).must_equal 'cannot convert String to xml'
      end

      it 'produces spans for endpoint_run and endpoint_render without errors despite the exception in formatter' do
        _(run_spans.size).must_equal 1
        _(render_spans.size).must_equal 1

        (run_spans + render_spans).each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
        end
      end
    end

    describe 'when an API endpoint returns an error without raising an exception' do
      class ErrorResponseAPI < Grape::API
        get :error_response do
          error!('Not found', 404)
        end
      end

      let(:app) { ErrorResponseAPI }
      let(:request_path) { '/error_response' }
      let(:expected_span_name) { 'GET /error_response' }

      before { get request_path }

      it 'does not set span status to error' do
        spans.each do |span|
          _(span.name).must_equal expected_span_name
          _(span.status.code).wont_equal OpenTelemetry::Trace::Status::ERROR
        end
      end
    end

    describe 'when an API endpoint receives a request and some events are ignored in the configs' do
      class IgnoredEventAPI < Grape::API
        get :success do
          'OK'
        end
      end

      let(:config) { { ignored_events: [:endpoint_render] } }
      let(:app) { IgnoredEventAPI }
      let(:request_path) { '/success' }
      let(:expected_span_name) { 'GET /success' }

      before { get request_path }

      it 'produces an endpoint_run span' do
        _(run_spans.length).must_equal 1

        span = run_spans.first

        _(span.name).must_equal expected_span_name
      end

      it 'does not produce a endpoint_render span' do
        _(render_spans.length).must_equal 0
      end
    end
  end
end
