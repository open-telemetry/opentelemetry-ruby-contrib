# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'base'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] = 'console'
# Configure OpenTelemetry::Instrumentation::Gruf
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Gruf', {
    peer_service: "Example",
    grpc_ignore_methods_on_client: [], # ["proto.example.example_api.example"]
    grpc_ignore_methods_on_server: [], # ["proto.example.example_api.example"]
    allowed_metadata_headers: [],
  }
end

# Configure Gruf::Server
Gruf.configure do |config|
  config.controllers_path = ("./controllers")
  config.interceptors.clear
  config.interceptors.use(OpenTelemetry::Instrumentation::Gruf::Interceptors::Server)
end
Gruf.autoloaders.load!(controllers_path: Gruf.controllers_path)

Thread.new do
 # Configure Gruf::Client: send request after 5 seconds
 sleep 5
 client_options = { interceptors: [OpenTelemetry::Instrumentation::Gruf::Interceptors::Client.new] }
 client = Gruf::Client.new(
   service: Proto::Example::ExampleAPI, options: {}, client_options: client_options
 )
 metadata = { project_name: "Example project", authorization: "authorization_token" }
 client.call(:Example, { id: 1, name: "Example"}, metadata)

 # Kill process after 3 seconds
 sleep 3
 exit
end

server = Gruf::Server.new
# Demonstrate tracing for client and server (span output to console):
server.start!
