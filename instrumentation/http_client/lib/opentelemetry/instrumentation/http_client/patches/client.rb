# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        # Module to prepend to HTTPClient for instrumentation
        module Client
          private

          def config
            HttpClient::Instrumentation.instance.config
          end

          def safe_execute_hook(hook, *args)
            hook.call(*args)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def do_get_block(req, proxy, conn, &block) # rubocop:disable Metrics/AbcSize
            uri = req.header.request_uri
            url = "#{uri.scheme}://#{uri.host}"
            request_method = req.header.request_method

            attributes = {
              'http.method' => request_method,
              'http.scheme' => uri.scheme,
              'http.target' => uri.path,
              'http.url' => url,
              'net.peer.name' => uri.host,
              'net.peer.port' => uri.port
            }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span("HTTP #{request_method}", attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.header)
              safe_execute_hook(config[:request_hook], span, req) unless config[:request_hook].nil?
              super.tap do
                response = conn.pop
                annotate_span_with_response!(span, response)
                conn.push response
              end
            end
          end

          def annotate_span_with_response!(span, response)
            return unless response&.status_code

            status_code = response.status_code.to_i

            span.set_attribute('http.status_code', status_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(status_code.to_i)
            safe_execute_hook(config[:response_hook], span, response) unless config[:response_hook].nil?
          end

          def tracer
            HttpClient::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
