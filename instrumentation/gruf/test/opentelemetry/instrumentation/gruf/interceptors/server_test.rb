# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

class TestServerInterceptor < OpenTelemetry::Instrumentation::Gruf::Interceptors::Server
  def initialize(request, error, options: {})
    super(request, error, options)
  end

  def call
    super

    'Test Server Call'
  end
end

class RpcTestCall
  attr_reader :metadata

  def initialize(parent: nil)
    @metadata = parent ? { 'traceparent' => parent } : {}
  end
end

describe OpenTelemetry::Instrumentation::Gruf::Interceptors::Server do
  before do
    instrumentation.install(config)
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  let(:config) { {} }
  let(:exporter) { EXPORTER }
  let(:instrumentation) { OpenTelemetry::Instrumentation::Gruf::Instrumentation.instance }
  let(:span) { exporter.finished_spans.first }
  let(:interceptor) { TestServerInterceptor }

  describe '#call' do
    let(:block) { proc { true } }
    let(:server_call) { interceptor.new(request, Gruf::Error.new) }
    let(:active_call) { RpcTestCall.new }

    let(:request) do
      Gruf::Controllers::Request.new(
        method_key: :example,
        service: Proto::Example::ExampleAPI::Service,
        rpc_desc: :description,
        active_call: active_call,
        message: Proto::Example::ExampleRequest.new
      )
    end

    describe 'success request' do
      it do
        expect(server_call.call(&block)).must_equal('Test Server Call')
        expect(exporter.finished_spans.size).must_equal(1)
        expect(span.attributes['rpc.system']).must_equal('grpc')
        expect(span.kind).must_equal(:server)
      end
    end

    describe 'with grpc_ignore_methods' do
      let(:config) { { grpc_ignore_methods_on_server: ['proto.example.example_api.example'] } }

      it do
        expect(server_call.call(&block)).must_equal('Test Server Call')
        expect(exporter.finished_spans.size).must_equal(0)
      end
    end

    describe 'when response with error' do
      let(:block) { proc { raise 'Invalid response' } }

      it do
        assert_raises RuntimeError do
          server_call.call(&block)
        end
        expect(exporter.finished_spans.size).must_equal(1)
      end
    end

    describe 'when request has parent span' do
      before do
        span = instrumentation.tracer.start_span('operation-name')
        span.finish
      end

      let(:span) { exporter.finished_spans.last }
      let(:parent_span) { exporter.finished_spans.first }
      let(:parent_span_id) { "00-#{parent_span.hex_trace_id}-#{parent_span.hex_span_id}-01" }
      let(:active_call) { RpcTestCall.new(parent: parent_span_id) }

      it do
        expect(server_call.call(&block)).must_equal('Test Server Call')
        expect(exporter.finished_spans.size).must_equal(2)
        expect(span.hex_trace_id).must_equal(parent_span.hex_trace_id)
      end
    end
  end
end
