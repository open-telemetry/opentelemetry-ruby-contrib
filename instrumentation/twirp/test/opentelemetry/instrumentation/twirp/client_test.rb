# # frozen_string_literal: true
#
# # Copyright The OpenTelemetry Authors
# #
# # SPDX-License-Identifier: Apache-2.0
#
# require 'test_helper'
# require_relative '../../../support/fake_services'
# require 'webmock/minitest'
#
# describe OpenTelemetry::Instrumentation::Twirp, 'Client' do
#   let(:instrumentation) { OpenTelemetry::Instrumentation::Twirp::Instrumentation.instance }
#   let(:exporter) { EXPORTER }
#   let(:spans) { exporter.finished_spans }
#   let(:client) do
#     Test::GreeterClient.new('http://localhost:8080')
#   end
#
#   before do
#     instrumentation.install
#
#     exporter.reset
#   end
#
#   after do
#     instrumentation.instance_variable_set(:@installed, false)
#
#     WebMock.reset!
#   end
#
#   describe 'when making successful RPC calls' do
#     before do
#       stub_request(:post, 'http://localhost:8080/test.Greeter/Greet')
#         .to_return(
#           status: 200,
#           body: Test::GreetReply.new(message: 'Hello, World!').to_proto,
#           headers: { 'Content-Type' => 'application/protobuf' }
#         )
#     end
#
#     it 'creates a client span' do
#       response = client.greet(Test::GreetRequest.new(name: 'World'))
#       _(response.data.message).must_equal 'Hello, World!'
#
#       _(spans.size).must_equal 1
#       span = spans.first
#       _(span.name).must_equal 'test.Greeter/Greet'
#       _(span.kind).must_equal :client
#       _(span.status.code).must_equal OpenTelemetry::Trace::Status::OK
#     end
#
#     it 'adds RPC semantic attributes' do
#       client.greet(Test::GreetRequest.new(name: 'World'))
#
#       span = spans.first
#       _(span.attributes['rpc.system']).must_equal 'twirp'
#       _(span.attributes['rpc.service']).must_equal 'test.Greeter'
#       _(span.attributes['rpc.method']).must_equal 'Greet'
#       _(span.attributes['rpc.twirp.content_type']).must_equal 'application/protobuf'
#     end
#
#     it 'adds network attributes' do
#       client.greet(Test::GreetRequest.new(name: 'World'))
#
#       span = spans.first
#       _(span.attributes['net.peer.name']).must_equal 'localhost'
#       _(span.attributes['net.peer.port']).must_equal 8080
#     end
#
#     it 'injects context propagation headers' do
#       client.greet(Test::GreetRequest.new(name: 'World'))
#
#       # Check that headers were injected
#       assert_requested(:post, 'http://localhost:8080/test.Greeter/Greet') do |req|
#         req.headers['Traceparent'] != nil
#       end
#     end
#
#     it 'uses peer_service when configured' do
#       instrumentation.instance_variable_set(:@installed, false)
#       instrumentation.install(peer_service: 'backend-service')
#
#       client.greet(Test::GreetRequest.new(name: 'World'))
#
#       span = spans.first
#       _(span.attributes['peer.service']).must_equal 'backend-service'
#     end
#   end
#
#   describe 'when RPC calls return errors' do
#     before do
#       error_response = {
#         code: 'invalid_argument',
#         msg: 'Invalid name'
#       }.to_json
#
#       stub_request(:post, 'http://localhost:8080/test.Greeter/Greet')
#         .to_return(
#           status: 400,
#           body: error_response,
#           headers: { 'Content-Type' => 'application/json' }
#         )
#     end
#
#     it 'records error attributes' do
#       response = client.greet(Test::GreetRequest.new(name: 'World'))
#       _(response.error).wont_be_nil
#
#       span = spans.first
#       _(span.attributes['rpc.twirp.error_code']).must_equal 'invalid_argument'
#       _(span.attributes['rpc.twirp.error_msg']).must_equal 'Invalid name'
#       _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
#     end
#   end
#
#   describe 'when network errors occur' do
#     before do
#       stub_request(:post, 'http://localhost:8080/test.Greeter/Greet')
#         .to_raise(Faraday::ConnectionFailed.new('Connection refused'))
#     end
#
#     it 'records the exception' do
#       _(-> { client.greet(Test::GreetRequest.new(name: 'World')) }).must_raise Faraday::ConnectionFailed
#
#       span = spans.first
#       _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
#       _(span.events.first.name).must_equal 'exception'
#     end
#   end
# end
