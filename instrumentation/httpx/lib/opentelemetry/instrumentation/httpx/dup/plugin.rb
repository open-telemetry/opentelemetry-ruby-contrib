# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      module Dup
        module Plugin
          # Instruments around HTTPX's request/response lifecycle in order to generate
          # an OTEL trace.
          module RequestTracer
            module_function

            # initializes tracing on the +request+.
            def call(request)
              span = nil

              # request objects are reused, when already buffered requests get rerouted to a different
              # connection due to connection issues, or when they already got a response, but need to
              # be retried. In such situations, the original span needs to be extended for the former,
              # while a new is required for the latter.
              request.on(:idle) do
                span = nil
              end
              # the span is initialized when the request is buffered in the parser, which is the closest
              # one gets to actually sending the request.
              request.on(:headers) do
                next if span

                span = initialize_span(request)
              end

              request.on(:response) do |response|
                unless span
                  next unless response.is_a?(::HTTPX::ErrorResponse) && response.error.respond_to?(:connection)

                  # handles the case when the +error+ happened during name resolution, which means
                  # that the tracing start point hasn't been triggered yet; in such cases, the approximate
                  # initial resolving time is collected from the connection, and used as span start time,
                  # and the tracing object in inserted before the on response callback is called.
                  span = initialize_span(request, response.error.connection.init_time)

                end

                finish(response, span)
              end
            end

            def finish(response, span)
              if response.is_a?(::HTTPX::ErrorResponse)
                span.record_exception(response.error)
                span.status = Trace::Status.error(response.error.to_s)
              else
                span.set_attribute(OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, response.status)
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

              span_data = HttpHelper.span_attrs_for(verb)

              config = HTTPX::Instrumentation.instance.config

              attributes = {
                OpenTelemetry::SemanticConventions::Trace::HTTP_HOST => uri.host,
                OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => span_data.normalized_method,
                OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => uri.scheme,
                OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => uri.path,
                OpenTelemetry::SemanticConventions::Trace::HTTP_URL => "#{uri.scheme}://#{uri.host}",
                OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => uri.host,
                OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => uri.port,
                'http.request.method' => span_data.normalized_method,
                'url.scheme' => uri.scheme,
                'url.path' => uri.path,
                'url.full' => "#{uri.scheme}://#{uri.host}",
                'server.address' => uri.host,
                'server.port' => uri.port
              }

              attributes['http.request.method_original'] = span_data.original_method if span_data.original_method
              attributes['url.query'] = uri.query unless uri.query.nil?
              attributes[OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] if config[:peer_service]
              attributes.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes)

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

          # Request patch to initiate the trace on initialization.
          module RequestMethods
            def initialize(*)
              super

              RequestTracer.call(self)
            end
          end

          # Connection patch to start monitoring on initialization.
          module ConnectionMethods
            attr_reader :init_time

            def initialize(*)
              super

              @init_time = ::Time.now
            end
          end
        end
      end
    end
  end
end
