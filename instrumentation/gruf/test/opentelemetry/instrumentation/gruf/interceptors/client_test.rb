# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/gruf'
require_relative '../../../../../lib/opentelemetry/instrumentation/gruf/interceptors/client'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message 'rpc.Request' do
    optional :id, :uint32, 1
    optional :name, :string, 2
  end
  add_message 'rpc.Response' do
    optional :thing, :message, 1, 'rpc.Request'
  end
end

describe OpenTelemetry::Instrumentation::Gruf::Interceptors::Client do
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
  let(:requests) do
    [::Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.Request').msgclass.new]
  end
  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: :request_response,
      requests: requests,
      call: proc { true },
      method: '/rpc.Request',
      metadata: { foo: 'bar' }
    )
  end
  let(:block) { proc { 'test' } }
  let(:client_call) do
    OpenTelemetry::Instrumentation::Gruf::Interceptors::Client
      .new.call(request_context: request_context, &block)
  end

  describe 'success request' do
    it 'gets response and finish span' do
      expect(client_call).must_equal 'test'
      expect(exporter.finished_spans.size).must_equal(1)
      expect(span.attributes['component']).must_equal('gRPC')
      expect(span.attributes['span.kind']).must_equal('client')
      expect(span.attributes['grpc.method_type']).must_equal('request_response')
      expect(span.events.size).must_equal(1)
    end
  end
  describe 'raise error' do
    let(:block) { proc { raise StandardError } }

    it 'gets response and finish span' do
      assert_raises StandardError do
        client_call
      end
      expect(exporter.finished_spans.size).must_equal(1)
      expect(span.attributes['component']).must_equal('gRPC')
      expect(span.attributes['span.kind']).must_equal('client')
      expect(span.attributes['grpc.method_type']).must_equal('request_response')
      expect(span.events.size).must_equal(2)
    end

    describe 'with exception_message is :full' do
      let(:config) { { exception_message: :full } }

      it 'exception with stacktrace' do
        assert_raises StandardError do
          client_call
        end
        expect(exporter.finished_spans.size).must_equal(1)
        expect(span.events.size).must_equal(2)
        expect(span.events.last.attributes["exception.stacktrace"].nil?).must_equal(false)
      end
    end
  end

  describe 'when span_name_client is present' do
    let(:config) { { span_name_client: proc { |context| "#{context.method} + custom" } } }

    it 'span name by span_name_client' do
      client_call

      expect(span.name).must_equal('/rpc.Request + custom')
    end
  end

  describe 'when log_requests_on_client is false' do
    let(:config) { { log_requests_on_client: false } }

    it 'logs is empty' do
      client_call

      assert_nil(span.events)
    end
  end
end
