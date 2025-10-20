# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../support/fake_services'
require 'rack'

describe OpenTelemetry::Instrumentation::Twirp, 'Server' do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Twirp::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:service) { Test::Greeter.new(GreeterHandler.new) }

  let(:app) do
    service_to_run = service

    Rack::Builder.new do
      map '/' do
        # TODO: this is required for the rack span to be recording?
        # Not sure how we can automate injecting this for twirp services
        use(*OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args)
        run service_to_run
      end
    end.to_app
  end

  before do
    exporter.reset

    instrumentation.install
  end

  after do
    # Reinstall with server instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'when handling successful requests' do
    it 'enriches Rack span with RPC attributes' do
      request = Test::GreetRequest.new(name: 'World')
      post '/test.Greeter/Greet', request.to_proto, 'CONTENT_TYPE' => 'application/protobuf'

      _(last_response.status).must_equal 200

      # Should have exactly one span from Rack
      _(spans.size).must_equal 1
      span = spans.first

      # Check that span was enriched with RPC attributes
      _(span.attributes['rpc.system']).must_equal 'twirp'
      _(span.attributes['rpc.service']).must_equal 'test.Greeter'
      _(span.attributes['rpc.method']).must_equal 'Greet'
      _(span.attributes['rpc.twirp.content_type']).must_equal 'application/protobuf'
    end

    it 'updates span name to RPC method' do
      request = Test::GreetRequest.new(name: 'World')
      post '/test.Greeter/Greet', request.to_proto, 'CONTENT_TYPE' => 'application/protobuf'

      span = spans.first
      _(span.name).must_equal 'test.Greeter/Greet'
    end
  end

  describe 'when handling JSON requests' do
    it 'adds JSON content type attribute' do
      request_json = { name: 'World' }.to_json
      post '/test.Greeter/Greet', request_json, 'CONTENT_TYPE' => 'application/json'

      _(last_response.status).must_equal 200
      span = spans.first
      _(span.attributes['rpc.twirp.content_type']).must_equal 'application/json'
    end
  end

  describe 'when handling invalid routes' do
    it 'still enriches the span' do
      post '/invalid/path', '', 'CONTENT_TYPE' => 'application/protobuf'

      _(last_response.status).must_equal 404
      # Span should still be created by Rack
      _(spans.size).must_equal 1
    end
  end

  describe 'when handler raises exceptions' do
    let(:service) { Test::Greeter.new(ErrorGreeterHandler.new) }

    it 'does not break the error handling' do
      request = Test::GreetRequest.new(name: 'World')
      post '/test.Greeter/Greet', request.to_proto, 'CONTENT_TYPE' => 'application/protobuf'

      # Twirp should return 500 with error
      _(last_response.status).must_equal 500

      span = spans.first
      _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
    end
  end
end
