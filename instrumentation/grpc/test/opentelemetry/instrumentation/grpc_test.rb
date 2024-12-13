# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'
require_relative '../../support/proto/ping_services_pb'
require_relative '../../support/grpc_server_runner'

describe OpenTelemetry::Instrumentation::Grpc do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Grpc::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:server_runner) { Support::GrpcServerRunner.new }

  before do
    instrumentation.install
    exporter.reset

    server_port = server_runner.start
    @stub = Support::Proto::PingServer::Stub.new(
      "localhost:#{server_port}",
      :this_channel_is_insecure,
    )
  end
  after do
    server_runner.stop
  end

  describe 'tracing' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      request = Support::Proto::PingRequest.new(value: 'Ping!')
      @stub.request_response_ping(request)

      _(exporter.finished_spans.size).must_equal 1
    end
  end
end
