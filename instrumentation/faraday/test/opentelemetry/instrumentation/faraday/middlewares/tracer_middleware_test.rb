# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/faraday/middlewares/tracer_middleware'

describe OpenTelemetry::Instrumentation::Faraday::Middlewares::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:response_body) { 'abcd1234' }

  let(:client) do
    ::Faraday.new('http://username:password@example.com') do |builder|
      builder.adapter(:test) do |stub|
        stub.get('/success') { |_| [200, {}, 'OK'] }
        stub.get('/failure') { |_| [500, {}, 'OK'] }
        stub.get('/not_found') { |_| [404, {}, 'OK'] }
        stub.get('/body') { |_| [200, {}, response_body] }
      end
    end
  end

  before do
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'first span' do
    before do
      instrumentation.install
    end

    it 'has http 200 attributes' do
      response = client.get('/success')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'has http.status_code 404' do
      response = client.get('/not_found')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 404
      _(span.attributes['http.url']).must_equal 'http://example.com/not_found'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'has http.status_code 500' do
      response = client.get('/failure')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'merges http client attributes' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE'
      }
      response = OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        client.get('/success')
      end

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'OVERRIDE'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(span.attributes['net.peer.name']).must_equal 'example.com'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client.get('/success')

      _(span.attributes['peer.service']).must_equal 'example:faraday'
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

  describe 'hooks' do
    let(:headers_attribute) { 'headers' }
    let(:response_body_attribute) { 'response_body' }

    describe 'valid hooks' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        config = {
          request_hook: lambda do |span, request|
            headers = {}
            request.request_headers.each do |k, v|
              headers[k] = v
            end
            span.set_attribute(headers_attribute, headers.to_json)
          end,
          response_hook: lambda do |span, response|
            span.set_attribute(response_body_attribute, response.body.to_s)
          end
        }

        instrumentation.install(config)
      end

      it 'collects data in request hook' do
        client.get('/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        headers = span.attributes[headers_attribute]
        _(headers).wont_be_nil
        parsed_headers = JSON.parse(headers)
        _(parsed_headers['traceparent']).wont_be_nil
        _(span.attributes[response_body_attribute]).must_equal response_body
      end
    end

    describe 'invalid hook - wrong number of args' do
      let(:received_exceptions) { [] }

      before do
        instrumentation.instance_variable_set(:@installed, false)
        config = {
          request_hook: ->(_span) { nil },
          response_hook: ->(_span) { nil }
        }

        instrumentation.install(config)
        OpenTelemetry.error_handler = lambda do |exception: nil, message: nil| # rubocop:disable Lint/UnusedBlockArgument
          received_exceptions << exception
        end
      end

      after do
        OpenTelemetry.error_handler = nil
      end

      it 'should not fail the instrumentation' do
        client.get('/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        error_messages = received_exceptions.map(&:message)
        _(error_messages.all? { |em| em.start_with?('wrong number of arguments') }).must_equal true
      end
    end

    describe 'invalid hooks - throws an error' do
      let(:error1) { 'err1' }
      let(:error2) { 'err2' }
      let(:received_exceptions) { [] }

      before do
        instrumentation.instance_variable_set(:@installed, false)
        config = {
          request_hook: ->(_span, _request) { raise StandardError, error1 },
          response_hook: ->(_span, _response) { raise StandardError, error2 }
        }

        instrumentation.install(config)
        OpenTelemetry.error_handler = lambda do |exception: nil, message: nil| # rubocop:disable Lint/UnusedBlockArgument
          received_exceptions << exception
        end
      end

      after do
        OpenTelemetry.error_handler = nil
      end

      it 'should not fail the instrumentation' do
        client.get('/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        error_messages = received_exceptions.map(&:message)
        _(error_messages).must_equal([error1, error2])
      end
    end
  end
end
