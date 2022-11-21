# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0


module OpenTelemetry
  module Instrumentation
    module Gruf
      module Interceptors
        class Client < ::Gruf::Interceptors::ClientInterceptor
          # rubocop:disable Metrics/MethodLength
          def call(request_context:)
            return yield if instrumentation_config.blank?

            service = request_context.method.split("/")[1]
            method = request_context.method_name
            method_name_with_service = [service.underscore, method].join(".").downcase

            if instrumentation_config[:grpc_ignore_methods_on_client].include?(method_name_with_service)
              return yield
            end

            metadata = request_context.metadata
            attributes = {
              'rpc.system' => 'grpc',
              'rpc.service' => service,
              'rpc.method' => method,
              'rpc.type' => request_context.type.to_s,
              'peer.service' => instrumentation_config[:peer_service],
            }.compact

            attributes.merge!(allowed_metadata_headers(metadata))

            instrumentation_tracer.in_span(request_context.method.to_s,
              attributes: attributes,
              kind: :client,
            ) do
              OpenTelemetry.propagation.inject(metadata)
              yield
            end
          end
          # rubocop:enable Metrics/MethodLength

          private

          def allowed_metadata_headers(metadata)
            build_key = -> (attribute) { "rpc.request.metadata.#{attribute}" }
            metadata.each_with_object({}) do |(k, v), h|
              h[build_key.call(k)] = v if instrumentation_config[:allowed_metadata_headers].include?(k.to_sym)
            end
          end

          def instrumentation_config
            Gruf::Instrumentation.instance.config
          end

          def instrumentation_tracer
            OpenTelemetry::Instrumentation::Gruf::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
