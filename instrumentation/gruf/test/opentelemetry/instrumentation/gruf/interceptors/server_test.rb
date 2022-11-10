# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/gruf'
require_relative '../../../../../lib/opentelemetry/instrumentation/gruf/interceptors/server'

class TestServerInterceptor < OpenTelemetry::Instrumentation::Gruf::Interceptors::Server
  def initialize(request, error, options: {})
    super(request, error, options)
  end

  def call
    super

    'Test Server Call'
  end
end

class TestService
  include GRPC::GenericService

  self.service_name = 'rpc.TestService'
end

class RpcTestCall
  attr_reader :metadata

  def initialize(parent: nil)
    @metadata = parent ? { 'traceparent' => parent } : {}
  end
end

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message 'rpc.Thing' do
    optional :id, :uint32, 1
    optional :name, :string, 2
  end
  add_message 'rpc.GetThingResponse' do
    optional :thing, :message, 1, 'rpc.Thing'
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
      ::Gruf::Controllers::Request.new(
        method_key: :get_thing,
        service: TestService,
        rpc_desc: :description,
        active_call: active_call,
        message: Google::Protobuf::DescriptorPool.generated_pool
                                                 .lookup('rpc.GetThingResponse').msgclass.new
      )
    end

    describe 'success request' do
      it do
        expect(server_call.call(&block)).must_equal('Test Server Call')
        expect(exporter.finished_spans.size).must_equal(1)
        expect(span.attributes['component']).must_equal('gRPC')
        expect(span.attributes['span.kind']).must_equal('server')
        expect(span.attributes['grpc.method_type']).must_equal('request_response')
      end
    end

    describe 'with grpc_ignore_methods' do
      let(:config) { { grpc_ignore_methods: ['test_service.get_thing'] } }

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

      describe 'with exception_message is :full' do
        let(:config) { { exception_message: :full } }

        it 'exception with stacktrace' do
          assert_raises StandardError do
            server_call.call(&block)
          end
          expect(exporter.finished_spans.size).must_equal(1)
          expect(span.events.size).must_equal(2)
          expect(span.events.last.attributes["exception.stacktrace"].nil?).must_equal(false)
        end
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

    describe 'when span_name_server is present' do
      let(:config) { { span_name_server: proc { |request| request.method_key.to_s } } }

      it 'span name by span_name_client' do
        server_call.call(&block)

        expect(span.name).must_equal('get_thing')
      end
    end

    describe 'when log_requests_on_server is false' do
      let(:config) { { log_requests_on_server: false } }

      it 'logs is empty' do
        server_call.call(&block)

        assert_nil(span.events)
      end
    end
  end
end
