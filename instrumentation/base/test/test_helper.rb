# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'opentelemetry-instrumentation-base'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

# Mock OpenTelemetry::SDK::Metrics module for testing when the SDK is not available
# TODO: This should move to test-helpers gem
unless defined?(OpenTelemetry::SDK::Metrics)
  module OpenTelemetry
    def self.meter_provider; end

    module SDK
      module Metrics
        # Mock Meter class
        class Meter
          attr_reader :name, :instrumentation_version

          def initialize(name, version:)
            @name = name
            @instrumentation_version = version
          end

          def create_histogram(name, unit: nil, description: nil)
            MockInstrument.new(name, unit, description)
          end

          def create_counter(name, unit: nil, description: nil)
            MockInstrument.new(name, unit, description)
          end

          def create_up_down_counter(name, unit: nil, description: nil)
            MockInstrument.new(name, unit, description)
          end

          def create_observable_counter(name, unit: nil, description: nil, &block)
            MockInstrument.new(name, unit, description)
          end

          def create_observable_gauge(name, unit: nil, description: nil, &block)
            MockInstrument.new(name, unit, description)
          end

          def create_observable_up_down_counter(name, unit: nil, description: nil, &block)
            MockInstrument.new(name, unit, description)
          end
        end

        # Mock MeterProvider class
        class MeterProvider
          def meter(name, version: nil)
            Meter.new(name, version: version)
          end
        end

        # Mock Instrument class for histograms, counters, etc.
        class MockInstrument
          attr_reader :name, :unit, :description

          def initialize(name, unit, description)
            @name = name
            @unit = unit
            @description = description
          end

          def record(value, attributes: {})
            # Mock record method
          end

          def add(value, attributes: {})
            # Mock add method
          end
        end
      end
    end
  end
end
