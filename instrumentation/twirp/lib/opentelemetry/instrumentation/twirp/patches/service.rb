# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Twirp
      module Patches
        # Module to be prepended to Twirp::Service to wrap with tracing middleware
        module Service
          def call(rack_env)
            # Extract context from incoming headers
            extracted_context = OpenTelemetry.propagation.extract(rack_env)
            OpenTelemetry::Context.with_current(extracted_context) do
              super
            end
          ensure
            enrich_span(rack_env) if OpenTelemetry::Instrumentation::Rack.current_span
          end

          private

          def enrich_span(rack_env)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span&.recording?

            # Extract RPC method from the path
            # Twirp URLs follow the pattern: POST {BaseURL}/{ServiceName}/{Method}
            path = rack_env['PATH_INFO'] || rack_env['REQUEST_PATH'] || ''
            path_parts = path.split('/')

            service_name = full_name
            rpc_method = path_parts.last if path_parts.size >= 2

            if rpc_method && !rpc_method.empty?
              # Set RPC semantic attributes
              span.set_attribute(OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM, 'twirp')
              span.set_attribute(OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE, service_name)
              span.set_attribute(OpenTelemetry::SemanticConventions::Trace::RPC_METHOD, rpc_method)

              # Update span name to RPC method
              span.name = "#{service_name}/#{rpc_method}"
            end

            # Add content type if available
            content_type = rack_env['CONTENT_TYPE']
            span.set_attribute('rpc.twirp.content_type', content_type) if content_type
          end
        end
      end
    end
  end
end
