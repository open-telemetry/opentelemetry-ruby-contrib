# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

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
    [Proto::Example::ExampleRequest.new]
  end
  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: :request_response,
      requests: requests,
      call: proc { true },
      method: '/proto.example.ExampleAPI/Example',
      metadata: { foo: 'bar' }
    )
  end
  let(:response) { Proto::Example::ExampleResponse.new(response_name: 'Done') }
  let(:block) { proc { response } }
  let(:client_call) do
    OpenTelemetry::Instrumentation::Gruf::Interceptors::Client
      .new.call(request_context: request_context, &block)
  end

  describe 'success request' do
    it 'gets response and finish span' do
      expect(client_call).must_equal response
      expect(exporter.finished_spans.size).must_equal(1)
      expect(span.kind).must_equal(:client)
      expect(span.attributes['rpc.system']).must_equal('grpc')
      expect(span.attributes['rpc.type']).must_equal('request_response')
    end

    describe 'with grpc_ignore_methods' do
      let(:config) { { grpc_ignore_methods_on_client: ['proto.example.example_api.example'] } }

      it do
        client_call

        expect(exporter.finished_spans.size).must_equal(0)
      end
    end

    describe 'with allowed_metadata_headers' do
      let(:config) { { allowed_metadata_headers: [:foo] } }

      it do
        client_call

        expect(exporter.finished_spans.size).must_equal(1)
        expect(span.attributes['rpc.request.metadata.foo']).must_equal('bar')
      end
    end
  end

  describe 'raise error' do
    let(:block) { proc { raise StandardError } }

    it 'gets response and finish span' do
      assert_raises StandardError do
        client_call
      end
      expect(exporter.finished_spans.size).must_equal(1)
      expect(span.kind).must_equal(:client)
      expect(span.attributes['rpc.system']).must_equal('grpc')
      expect(span.attributes['rpc.type']).must_equal('request_response')
      expect(span.events.size).must_equal(1)
      expect(span.events.first.name).must_equal('exception')
    end
  end
end
