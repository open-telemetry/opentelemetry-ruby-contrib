# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RestClient
      module Patches
        # Module to prepend to RestClient::Request for instrumentation
        module Request
          def execute(&block)
            trace_request do |_span|
              super(&block)
            end
          end

          private

          def config
            RestClient::Instrumentation.instance.config
          end

          def safe_execute_hook(hook, *args)
            hook.call(*args)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def create_request_span
            http_method = method.upcase
            instrumentation_attrs = {
              'http.method' => http_method.to_s,
              'http.url' => OpenTelemetry::Common::Utilities.cleanse_url(url)
            }
            instrumentation_config = RestClient::Instrumentation.instance.config
            instrumentation_attrs['peer.service'] = instrumentation_config[:peer_service] if instrumentation_config[:peer_service]
            span = tracer.start_span(
              "HTTP #{http_method}",
              attributes: instrumentation_attrs.merge(
                OpenTelemetry::Common::HTTP::ClientContext.attributes
              ),
              kind: :client
            )

            OpenTelemetry::Trace.with_span(span) do
              OpenTelemetry.propagation.inject(processed_headers)
            end
            safe_execute_hook(instrumentation_config[:request_hook], span, self) unless instrumentation_config[:request_hook].nil?

            span
          end

          def trace_request
            span = create_request_span

            yield(span).tap do |response|
              # Verify return value is a response.
              # If so, add additional attributes.
              if response.is_a?(::RestClient::Response)
                span.set_attribute('http.status_code', response.code)
                span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response.code.to_i)
                safe_execute_hook(config[:response_hook], span, response) unless config[:response_hook].nil?
              end
            end
          rescue ::RestClient::ExceptionWithResponse => e
            span.set_attribute('http.status_code', e.http_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(e.http_code.to_i)

            raise e
          ensure
            span.finish
          end

          def tracer
            RestClient::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
