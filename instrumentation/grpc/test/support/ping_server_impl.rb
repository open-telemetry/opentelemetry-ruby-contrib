# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'proto/ping_services_pb'

class PingServerImpl < Support::Proto::PingServer::Service
  def request_response_ping(ping_request, _call)
    Support::Proto::PingResponse.new(value: 'Pong!')
  end
end
