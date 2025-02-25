# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Metrics do
  let(:instrumentation_with_metrics) do
    Class.new(OpenTelemetry::Instrumentation::Base) do
      instrumentation_name 'test_instrumentation'
      instrumentation_version '0.1.1'

      option :metrics, default: false, validate: :boolean

      install { true }
      present { true }

      if defined?(OpenTelemetry::Metrics)
        counter 'example.counter'
        observable_counter 'example.observable_counter'
        histogram 'example.histogram'
        gauge 'example.gauge'
        observable_gauge 'example.observable_gauge'
        up_down_counter 'example.up_down_counter'
        observable_up_down_counter 'example.observable_up_down_counter'
      end

      def example_counter
        counter 'example.counter'
      end

      def example_observable_counter
        observable_counter 'example.observable_counter'
      end

      def example_histogram
        histogram 'example.histogram'
      end

      def example_gauge
        gauge 'example.gauge'
      end

      def example_observable_gauge
        observable_gauge 'example.observable_gauge'
      end

      def example_up_down_counter
        up_down_counter 'example.up_down_counter'
      end

      def example_observable_up_down_counter
        observable_up_down_counter 'example.observable_up_down_counter'
      end
    end
  end

  let(:config) { {} }
  let(:instance) { instrumentation_with_metrics.instance }

  before do
    instance.install(config)
  end

  if defined?(OpenTelemetry::Metrics)
    describe 'with the metrics api' do
      it 'is disabled by default' do
        _(instance.metrics_enabled?).must_equal false
      end

      it 'returns a no-op counter' do
        counter = instance.example_counter
        _(counter).must_be_kind_of(OpenTelemetry::Metrics::Instrument::Counter)
      end

      describe 'with the option enabled' do
        let(:config) { { metrics: true } }

        it 'will be enabled' do
          _(instance.metrics_enabled?).must_equal true
        end

        it 'returns a counter', with_metrics_sdk: true do
          counter = instance.example_counter

          _(counter).must_be_kind_of(OpenTelemetry::SDK::Metrics::Instrument::Counter)
        end
      end
    end
  else
    describe 'without the metrics api' do
      it 'will not be enabled' do
        _(instance.metrics_enabled?).must_equal false
      end

      it 'returns no instruments' do
        counter = instance.example_counter
        _(counter).must_be_nil
      end

      describe 'with the option enabled' do
        let(:config) { { metrics: true } }

        it 'will not be enabled' do
          _(instance.metrics_enabled?).must_equal false
        end
      end
    end
  end
end
