# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/status'

module OpenTelemetry
  module Instrumentation
    module Gruf
      module Interceptors
        class Server < ::Gruf::Interceptors::ServerInterceptor
          # rubocop:disable Metrics/MethodLength
          def call
            method = request.method_name

            if (instrumentation_config[:grpc_ignore_methods] || []).include?(method)
              OpenTelemetry::Common::Utilities.untraced do
                return yield
              end
            end

            service_name = request.service.service_name.to_s
            method_name = request.method_key.to_s
            route = "/#{service_name}/#{method_name.camelize}"

            attributes = {
              'component' => 'gRPC',
              'span.kind' => 'server',
              'grpc.method_type' => 'request_response',
              'grpc.service_name' => service_name,
              'grpc.method_name' => method_name
            }
            # rubocop:disable Style/IfUnlessModifier
            if instrumentation_config[:peer_service]
              attributes['peer.service'] = instrumentation_config[:peer_service]
            end
            # rubocop:enable Style/IfUnlessModifier

            extracted_context = OpenTelemetry.propagation.extract(request.active_call.metadata)
            OpenTelemetry::Context.with_current(extracted_context) do
              in_span(
                create_span_name(route, request, attributes['peer.service']),
                attributes: attributes
              ) do |request_span|
                if instrumentation_config[:log_requests_on_server]
                  request_span.add_event(
                    'request',
                    attributes: {
                      'data' => JSON.dump(request.message.to_h)
                    }
                  )
                end

                yield
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

          private

          def in_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil, &block)
            span = nil
            span = instrumentation_tracer.start_span(
              name, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind
            )
            Trace.with_span(span, &block)
          rescue Exception => e # rubocop:disable Lint/RescueException
            record_exception(span, e)
            span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
            raise e
          ensure
            span&.finish
          end

          def record_exception(span, exception)
            if instrumentation_config[:exception_message] == :full
              span&.record_exception(exception)
            else
              event_attributes = {
                'exception.type' => exception.class.to_s,
                'exception.message' => exception.message,
              }
              span&.add_event('exception', attributes: event_attributes)
            end
          end

          def instrumentation_config
            Gruf::Instrumentation.instance.config
          end

          def create_span_name(route, request, peer_service)
            if (implementation = instrumentation_config[:span_name_server])
              implementation.call(request, peer_service)
            else
              route
            end
          end

          def instrumentation_tracer
            OpenTelemetry::Instrumentation::Gruf::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
