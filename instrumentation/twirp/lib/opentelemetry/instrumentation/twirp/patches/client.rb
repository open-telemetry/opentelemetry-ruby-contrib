# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'debug'
module OpenTelemetry
  module Instrumentation
    module Twirp
      module Patches
        # Module to be prepended to Twirp::Client to instrument RPC calls
        module Client
          def rpc(rpc_method, input, req_opts = nil)
            rpcdef = self.class.rpcs[rpc_method.to_s]
            return super unless rpcdef

            service_name = @service_full_name
            method_name = rpc_method.to_s

            attributes = {
              OpenTelemetry::SemanticConventions::Trace::RPC_SYSTEM => 'twirp',
              OpenTelemetry::SemanticConventions::Trace::RPC_SERVICE => service_name,
              OpenTelemetry::SemanticConventions::Trace::RPC_METHOD => method_name,
              'rpc.twirp.content_type' => @content_type
            }

            # Add peer service if configured
            peer_service = instrumentation_config[:peer_service]
            attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = peer_service if peer_service

            # Extract HTTP attributes from the Faraday connection
            if @conn.respond_to?(:url_prefix)
              url_prefix = @conn.url_prefix
              attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME] = url_prefix.host if url_prefix.host
              attributes[OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT] = url_prefix.port if url_prefix.port
            end

            attributes.compact!

            instrumentation_tracer.in_span(
              "#{service_name}/#{method_name}",
              attributes: attributes,
              kind: OpenTelemetry::Trace::SpanKind::CLIENT
            ) do |span|
              # Inject context propagation headers into req_opts
              req_opts ||= {}
              req_opts[:headers] ||= {}
              OpenTelemetry.propagation.inject(req_opts[:headers])

              response = super(rpc_method, input, req_opts)

              # Handle response
              if response.error
                error = response.error
                span.set_attribute('rpc.twirp.error_code', error.code.to_s) if error.code
                span.set_attribute('rpc.twirp.error_msg', error.msg) if error.msg

                # Set span status based on error code
                span.status = OpenTelemetry::Trace::Status.error(error.msg || error.code.to_s)
              else
                span.status = OpenTelemetry::Trace::Status.ok
              end

              response
            rescue StandardError => e
              span&.record_exception(e)
              span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception: #{e.class}")
              raise
            end
          end

          private

          def instrumentation_config
            Twirp::Instrumentation.instance.config
          end

          def instrumentation_tracer
            Twirp::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
