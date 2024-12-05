# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require "spec_helper"

require "opentelemetry/instrumentation/grpc/interceptors/client"

RSpec.describe OpenTelemetry::Instrumentation::Grpc::Interceptors::Client do
  before do
    instrumentation.install(config)
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  let(:config) { {} }
  let(:exporter) { EXPORTER }
  let(:instrumentation) { OpenTelemetry::Instrumentation::Grpc::Instrumentation.instance }
  let(:span) { exporter.finished_spans.first }
  let(:response) { Proto::Example::ExampleResponse.new(response_name: "Done") }
  let(:block) { proc { response } }
  let(:client_call) do
    OpenTelemetry::Instrumentation::Grpc::Interceptors::Client
      .new.request_response(request: Proto::Example::ExampleRequest.new, call: proc { true }, method: "/proto.example.ExampleAPI/Example", metadata: {foo: "bar"}, &block)
  end

  describe "success request" do
    it "gets response and finish span" do
      expect(client_call).to eq(response)
      expect(exporter.finished_spans.size).to eq(1)
      expect(span.kind).to eq(:client)
      expect(span.attributes["rpc.system"]).to eq("grpc")
      expect(span.attributes["rpc.type"]).to eq("request_response")
      expect(span.name).to eq("proto.example.ExampleAPI/Example")
    end

    describe "with allowed_metadata_headers" do
      let(:config) { {allowed_metadata_headers: [:foo]} }

      it do
        client_call

        expect(exporter.finished_spans.size).to eq(1)
        expect(span.attributes["rpc.request.metadata.foo"]).to eq("bar")
      end
    end
  end

  describe "raise non-gRPC related error" do
    let(:error_class) { Class.new(StandardError) }
    let(:block) { proc { raise error_class } }

    it "gets response and finish span" do
      expect { client_call }.to raise_error(error_class)
      expect(exporter.finished_spans.size).to eq(1)
      expect(span.kind).to eq(:client)
      expect(span.attributes["rpc.system"]).to eq("grpc")
      expect(span.attributes["rpc.type"]).to eq("request_response")
      expect(span.events.size).to eq(1)
      expect(span.events.first.name).to eq("exception")
    end
  end

  describe "raise gRPC related error" do
    let(:block) { proc { raise ::GRPC::NotFound } }

    it "gets response and finish span, setting code correctly" do
      expect { client_call }.to raise_error(::GRPC::NotFound)
      expect(exporter.finished_spans.size).to eq(1)
      expect(span.kind).to eq(:client)
      expect(span.attributes["rpc.system"]).to eq("grpc")
      expect(span.attributes["rpc.type"]).to eq("request_response")
      expect(span.attributes["rpc.grpc.status_code"]).to eq(::GRPC::NotFound.new.code)
      expect(span.events.size).to eq(1)
    end
  end
end
