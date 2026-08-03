# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../plugin'

module OpenTelemetry
  module Instrumentation
    module HTTPX
      module Stable
        # Stable Plugin
        module Plugin
          class << self
            # session start dependencies
            def load_dependencies(klass)
              klass.plugin(HTTPX::Plugin)
            end

            # session extra options
            def extra_options(options)
              options.merge(tracer: Stable::RequestTracer)
            end
          end
        end

        # Instruments around HTTPX's request/response lifecycle in order to generate
        # an OTEL trace.
        module RequestTracer
          extend HTTPX::Plugin::RequestTracer
          extend self

          private

          def finish_span(response, span)
            if response.is_a?(::HTTPX::ErrorResponse)
              span.record_exception(response.error)
              span.status = Trace::Status.error(response.error.to_s)
            else
              span.set_attribute('http.response.status_code', response.status)

              if response.status.between?(400, 599)
                err = ::HTTPX::HTTPError.new(response)
                span.record_exception(err)
                span.status = Trace::Status.error(err.to_s)
              end
            end

            span.finish
          end

          # return a span initialized with the +@request+ state.
          def initialize_span(request, start_time = ::Time.now)
            verb = request.verb
            uri = request.uri

            span_data = HttpHelper.span_attrs_for_stable(verb)

            config = HTTPX::Instrumentation.instance.config

            attributes = {
              'url.scheme' => uri.scheme,
              'url.path' => uri.path,
              'url.full' => "#{uri.scheme}://#{uri.host}",
              'server.address' => uri.host,
              'server.port' => uri.port
            }
            attributes['url.query'] = uri.query unless uri.query.nil?
            attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] if config[:peer_service]
            attributes.merge!(span_data.attributes)

            span = tracer.start_span(span_data.span_name, attributes: attributes, kind: :client, start_timestamp: start_time)

            OpenTelemetry::Trace.with_span(span) do
              OpenTelemetry.propagation.inject(request.headers)
            end

            span
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def tracer
            HTTPX::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
