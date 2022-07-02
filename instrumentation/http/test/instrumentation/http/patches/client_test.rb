# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/http'
require_relative '../../../../lib/opentelemetry/instrumentation/http/patches/client'

describe OpenTelemetry::Instrumentation::HTTP::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    instrumentation.install({})
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe '#perform' do
    it 'traces a simple request' do
      ::HTTP.get('http://example.com/success')

      _(exporter.finished_spans.size).must_equal(1)
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
      ::HTTP.post('http://example.com/failure')

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
        ::HTTP.get('https://example.com/timeout')
      end.must_raise HTTP::TimeoutError

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
        'Unhandled exception of type: HTTP::TimeoutError'
      )
      assert_requested(
        :get,
        'https://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges http client attributes' do
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo') do
        ::HTTP.get('http://example.com/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
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
            request.headers.each do |k, v|
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
        ::HTTP.get('http://example.com/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        headers = span.attributes[headers_attribute]
        _(headers).wont_be_nil
        parsed_headers = JSON.parse(headers)
        _(parsed_headers['Traceparent']).wont_be_nil
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
        ::HTTP.get('http://example.com/body')
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
        ::HTTP.get('http://example.com/body')
        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'HTTP GET'
        _(span.attributes['http.method']).must_equal 'GET'
        error_messages = received_exceptions.map(&:message)
        _(error_messages).must_equal([error1, error2])
      end
    end
  end
end
