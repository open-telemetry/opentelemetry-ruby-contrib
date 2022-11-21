# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Gruf
      module Interceptors
        class Server < ::Gruf::Interceptors::ServerInterceptor
          # rubocop:disable Metrics/MethodLength
          def call
            return yield if instrumentation_config.blank?

            method = request.method_name

            if instrumentation_config[:grpc_ignore_methods_on_server].include?(method)
              return yield
            end

            service_name = request.service.service_name.to_s
            method_name = request.method_key.to_s
            route = "/#{service_name}/#{method_name.camelize}"

            attributes = {
              'rpc.system' => 'grpc',
              'rpc.service' => service_name,
              'rpc.method' => method_name,
              'peer.service' => instrumentation_config[:peer_service],
            }.compact

            extracted_context = OpenTelemetry.propagation.extract(request.active_call.metadata)
            OpenTelemetry::Context.with_current(extracted_context) do
              instrumentation_tracer.in_span(route, attributes: attributes, kind: :server,) do |_span|
                yield
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

          private

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
