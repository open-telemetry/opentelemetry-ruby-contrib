# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      module Patches
        # Module to prepend to HTTP::Connection for instrumentation
        module Connection
          def initialize(req, options)
            attributes = {}

            sem_conv.set_http_net_peer_name_client(attributes, req.uri.host)
            sem_conv.set_http_peer_port_client(attributes, req.uri.port)
            attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span('HTTP CONNECT', attributes: attributes) do
              super
            end
          end

          private

          def tracer
            HTTP::Instrumentation.instance.tracer
          end

          def sem_conv
            HTTP::Instrumentation.instance.sem_conv
          end
        end
      end
    end
  end
end
