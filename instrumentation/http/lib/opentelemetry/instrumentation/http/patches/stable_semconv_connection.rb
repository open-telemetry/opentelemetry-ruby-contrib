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
          module Stable
            def initialize(req, options)
              attributes = {
                'server.address' => req.uri.host,
                'server.port' => req.uri.port
              }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

              tracer.in_span('HTTP CONNECT', attributes: attributes) do
                super
              end
            end

            private

            def tracer
              HTTP::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
