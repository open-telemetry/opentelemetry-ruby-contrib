# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      module Stable
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
                span = initialize_span(request, request.init_time) if !span && request.init_time

                finish(response, span)
              end
            end

            def finish(response, span)
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

          # Request patch to initiate the trace on initialization.
          module RequestMethods
           attr_accessor :init_time

            # intercepts request initialization to inject the tracing logic.
            def initialize(*)
              super

              @init_time = nil

              RequestTracer.call(self)
            end

            def response=(*)
              # init_time should be set when it's send to a connection.
              # However, there are situations where connection initialization fails.
              # Example is the :ssrf_filter plugin, which raises an error on
              # initialize if the host is an IP which matches against the known set.
              # in such cases, we'll just set here right here.
              @init_time ||=  ::Time.now

              super
            end
          end

          module ConnectionMethods
            def initialize(*)
              super

              @init_time = ::Time.now
            end

            def send(request)
              request.init_time ||= @init_time

              super
            end
          end
        end
      end
    end
  end
end
