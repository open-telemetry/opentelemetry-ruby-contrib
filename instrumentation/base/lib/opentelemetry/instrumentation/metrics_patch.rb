# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # MetricsPatch is a module that provides functionality to create a meter
    # and record metrics if both the opentelemetry-metrics-api is present
    # and the instrumentation to emit metrics has enabled metrics by setting
    # :send_metrics to true
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
