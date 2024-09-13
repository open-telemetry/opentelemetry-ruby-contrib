# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      module Patches
        # Module to prepend to HTTP::Client for instrumentation
        module Client
          def perform(req, options)
            uri = req.uri
            request_method = req.verb.to_s.upcase
            span_name = create_request_span_name(request_method, uri.path)

            attributes = {}
            sem_conv.set_http_method(attributes, request_method)
            sem_conv.set_http_scheme(attributes, uri.scheme)
            sem_conv.set_http_target(attributes, uri.path, uri.query)
            sem_conv.set_http_url(attributes, "#{uri.scheme}://#{uri.host}")
            sem_conv.set_http_net_peer_name_client(attributes, uri.host)
            sem_conv.set_http_peer_port_client(attributes, uri.port)

            attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span(span_name, attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.headers)
              super.tap do |response|
                annotate_span_with_response!(span, response)
              end
            end
          end

          private

          def config
            OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance.config
          end

          def annotate_span_with_response!(span, response)
            return unless response&.status

            status_code = response.status.to_i
            sem_conv_status_code = {}
            sem_conv.set_http_status_code(sem_conv_status_code, status_code)
            span.add_attributes(sem_conv_status_code)

            span.status = OpenTelemetry::Trace::Status.error unless (100..399).cover?(status_code)
          end

          def create_request_span_name(request_method, request_path)
            if (implementation = config[:span_name_formatter])
              updated_span_name = implementation.call(request_method, request_path)
              updated_span_name.is_a?(String) ? updated_span_name : "HTTP #{request_method}"
            else
              "HTTP #{request_method}"
            end
          rescue StandardError
            "HTTP #{request_method}"
          end

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
