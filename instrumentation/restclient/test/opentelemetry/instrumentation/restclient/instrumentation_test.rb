# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/restclient'
require_relative '../../../../lib/opentelemetry/instrumentation/restclient/patches/request'

describe OpenTelemetry::Instrumentation::RestClient::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RestClient::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/failure').to_return(status: 500)

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'tracing' do
    before do
      instrumentation.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      ::RestClient.get('http://username:password@example.com/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      expect do
        ::RestClient.get('http://username:password@example.com/failure')
      end.must_raise RestClient::InternalServerError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      assert_requested(
        :get,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges HTTP client context' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE'
      }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        ::RestClient.get('http://username:password@example.com/success')
      end

      _(span.attributes['http.method']).must_equal 'OVERRIDE'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      ::RestClient.get('http://example.com/success')
      _(span.attributes['peer.service']).must_equal 'example:faraday'
    end

    it 'prioritizes context attributes over config for peer service name' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client_context_attrs = { 'peer.service' => 'example:custom' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        ::RestClient.get('http://example.com/success')
      end
      _(span.attributes['peer.service']).must_equal 'example:custom'
    end

    it 'creates valid http method span attribute when method is a Symbol' do
      ::RestClient::Request.execute(method: :get, url: 'http://username:password@example.com/success')

      _(span.attributes['http.method']).must_equal 'GET'
    end
  end

  describe 'hooks' do
    let(:response_body) { 'abcd1234' }
    let(:headers_attribute) { 'headers' }
    let(:response_body_attribute) { 'response_body' }

    before do
      stub_request(:get, 'http://example.com/body').to_return(status: 200, body: response_body)
    end

    describe 'valid hooks' do
      before do
        instrumentation.instance_variable_set(:@installed, false)
        config = {
          request_hook: lambda do |span, request|
            headers = {}
            request.processed_headers.each do |k, v|
              headers[k] = v
            end
            span.set_attribute(headers_attribute, headers.to_json)
          end,
          response_hook: lambda do |span, response|
            span.set_attribute(response_body_attribute, response.body)
          end
        }

        instrumentation.install(config)
      end

      it 'collects data in request hook' do
        ::RestClient.get('http://example.com/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        headers = span.attributes[headers_attribute]
        _(headers).wont_be_nil
        parsed_headers = JSON.parse(headers)
        _(parsed_headers['User-Agent']).must_include 'rest-client'
        _(span.attributes[response_body_attribute]).must_equal response_body
      end
    end

    describe 'when hooks are configured with incorrect number of args' do
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
        ::RestClient.get('http://example.com/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        error_messages = received_exceptions.map(&:message)
        _(error_messages.all? { |em| em.start_with?('wrong number of arguments') }).must_equal true
      end
    end

    describe 'when exceptions are thrown in hooks' do
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
        ::RestClient.get('http://example.com/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        error_messages = received_exceptions.map(&:message)
        _(error_messages).must_equal([error1, error2])
      end
    end
  end
end
