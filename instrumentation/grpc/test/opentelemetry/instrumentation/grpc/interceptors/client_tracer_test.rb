# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../test_helper'
require_relative '../../../../support/grpc_server_runner'
require_relative '../../../../../lib/opentelemetry/instrumentation/grpc/interceptors/client_tracer'

describe OpenTelemetry::Instrumentation::Grpc::Interceptors::ClientTracer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Grpc::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:request) { Support::Proto::PingRequest.new(value: 'Ping!') }
  let(:server_runner) { Support::GrpcServerRunner.new }

  before do
    instrumentation.install
    exporter.reset

    # use a real gRPC server to avoid non-trivial mocks
    server_port = server_runner.start
    # create a client stub to interact with the server
    @stub = Support::Proto::PingServer::Stub.new(
      "localhost:#{server_port}",
      :this_channel_is_insecure
    )
  end
  after do
    server_runner.stop
  end

  describe '#request_response' do
    it 'registers a span' do
      _(exporter.finished_spans.size).must_equal 0

      @stub.request_response_ping(request)

      _(exporter.finished_spans.size).must_equal 1
    end

    it 'sets expected kind' do
      @stub.request_response_ping(request)

      span = exporter.finished_spans.first

      _(span).wont_be_nil
      _(span.kind).must_equal(:client)
    end

    it 'sets expected name' do
      @stub.request_response_ping(request)

      span = exporter.finished_spans.first

      _(span).wont_be_nil
      _(span.name).must_equal('support.proto.PingServer/RequestResponsePing')
    end

    it 'sets expected attributes' do
      @stub.request_response_ping(request)

      span = exporter.finished_spans.first

      _(span).wont_be_nil
      _(span.attributes['rpc.system']).must_equal('grpc')
      _(span.attributes['rpc.service']).must_equal('support.proto.PingServer')
      _(span.attributes['rpc.method']).must_equal('RequestResponsePing')
      _(span.attributes['rpc.type']).must_equal('request_response')
      _(span.attributes['net.sock.peer.addr']).wont_be_empty
      _(span.attributes['rpc.grpc.status_code']).must_equal(0)
    end
  end
end
