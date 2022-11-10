# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/status'

module OpenTelemetry
  module Instrumentation
    module Gruf
      module Interceptors
        class Client < ::Gruf::Interceptors::ClientInterceptor
          # rubocop:disable Metrics/MethodLength
          def call(request_context:)
            metadata = request_context.metadata

            attributes = {
              'component' => 'gRPC',
              'span.kind' => 'client',
              'grpc.method_type' => 'request_response',
              'grpc.headers' => JSON.dump(metadata)
            }
            # rubocop:disable Style/IfUnlessModifier
            if instrumentation_config[:peer_service]
              attributes['peer.service'] = instrumentation_config[:peer_service]
            end
            # rubocop:enable Style/IfUnlessModifier

            in_span(
              create_span_name(request_context, attributes['peer.service']),
              attributes: attributes
            ) do |span|
              OpenTelemetry.propagation.inject(metadata)
              if instrumentation_config[:log_requests_on_client]
                span.add_event(
                  'request',
                  attributes: {
                    'data' => JSON.dump(request_context.requests.map(&:to_h))
                  }
                )
              end

              yield
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

          def create_span_name(request_context, peer_service)
            if (implementation = instrumentation_config[:span_name_client])
              implementation.call(request_context, peer_service)
            else
              request_context.method.to_s
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
