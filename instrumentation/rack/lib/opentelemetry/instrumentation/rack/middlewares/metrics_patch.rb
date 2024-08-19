module OpenTelemetry
  module Instrumentation
    module Rack
      module Middlewares
        module MetricsPatch
          # Don't check in here to see if metrics is enabled, trust that if it's required, metrics will be enabled
          def meter
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.meter
          end

          def http_server_request_duration_histogram
            # TODO: Add Advice to set small explicit histogram bucket boundaries
            # TODO: Does this need to be memoized?
            @http_server_request_duration_histogram ||= meter.create_histogram('http.server.request.duration', unit: 's', description: 'Duration of HTTP server requests.')
          end

          def record_http_server_request_duration_metric(span)
            # find span duration
            # end - start / a billion to convert nanoseconds to seconds
            duration = (span.end_timestamp - span.start_timestamp) / Float(10**9)
            # Create attributes
            #
            attrs = {}
            # pattern below goes
            # stable convention
            # current span convention

            # attrs['http.request.method']
            attrs['http.method'] = span.attributes['http.method']

            # attrs['url.scheme']
            attrs['http.scheme'] = span.attributes['http.scheme']

            # same in stable semconv
            attrs['http.route'] = span.attributes['http.route']

            # attrs['http.response.status.code']
            attrs['http.status_code'] = span.attributes['http.status_code']

            # attrs['server.address'] ???
            # attrs['server.port'] ???
            # span includes host and port
            attrs['http.host'] = span.attributes['http.host']

            # attrs not currently in span payload
            # attrs['network.protocol.version']
            # attrs['network.protocol.name']
            attrs['error.type'] = span.status.description if span.status.code == OpenTelemetry::Trace::Status::ERROR

            http_server_request_duration_histogram.record(duration, attributes: attrs)
          end
        end
      end
    end
  end
end

OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler.prepend(OpenTelemetry::Instrumentation::Rack::Middlewares::MetricsPatch)
