# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# inspired by https://github.com/grpc/grpc/blob/master/src/ruby/spec/support/helpers.rb

require_relative 'ping_server_impl'

module Support
  class GrpcServerRunner
    def initialize(service: PingServerImpl, server_opts: {})
      @service = service
      @server_opts = server_opts
    end

    def start
      @server_opts[:pool_size] ||= 1
      @server_opts[:poll_period] ||= 1
      @server = GRPC::RpcServer.new(**@server_opts)
      @server_port = @server.add_http2_port(
        'localhost:0', :this_port_is_insecure
      )
      @server.handle(@service)
      @server_thread = Thread.new { @server.run }
      @server.wait_till_running
      @server_port
    end

    def stop
      @server.stop
      @server_thread.join
    end
  end
end
