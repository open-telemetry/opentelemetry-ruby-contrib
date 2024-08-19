module OpenTelemetry
  module Instrumentation
    module MetricsPatch
      def create_meter
        @meter = OpenTelemetry::Metrics::Meter.new
      end

      def install_meter
        @meter = OpenTelemetry.meter_provider.meter(name, version: version) if metrics_enabled?
      end

      def metrics_enabled?
        return @metrics_enabled if defined?(@metrics_enabled)

        @metrics_enabled ||= defined?(OpenTelemetry::Metrics) && @config[:send_metrics]
      end
    end
  end
end

OpenTelemetry::Instrumentation::Base.prepend(OpenTelemetry::Instrumentation::MetricsPatch)
