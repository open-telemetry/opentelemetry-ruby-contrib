# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'OpenTelemetry::AutoInstrumentation' do
  let(:auto_instrumentation_path) { File.expand_path('../lib/opentelemetry-auto-instrumentation.rb', __dir__) }

  before do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
    ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = nil
    ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] = nil
  end

  # Verifies that loading the auto-instrumentation gem initialises the TracerProvider
  # with the SDK implementation and attaches the expected resource attributes and
  # default instrumentation libraries.
  it 'simple_load_test' do
    result = run_in_subprocess

    _(result[:error]).must_be_nil
    _(result[:tracer_provider_class]).must_equal 'OpenTelemetry::SDK::Trace::TracerProvider'
    _(result[:resource_attributes]['service.name']).must_equal 'unknown_service'
    _(result[:resource_attributes]['telemetry.sdk.name']).must_equal 'opentelemetry'
    _(result[:resource_attributes]['telemetry.sdk.language']).must_equal 'ruby'
    _(result[:resource_attributes].key?('container.id')).must_equal false
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Rake'
  end

  # Verifies that setting OTEL_RUBY_INSTRUMENTATION_<NAME>_ENABLED=false suppresses
  # a specific instrumentation while leaving others active.
  it 'simple_load_with_net_http_disabled' do
    result = run_in_subprocess('OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED' => 'false')

    _(result[:error]).must_be_nil
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Rake'
    _(result[:instrumentation_names]).wont_include 'OpenTelemetry::Instrumentation::Net::HTTP'
  end

  # Verifies that OTEL_RUBY_ENABLED_INSTRUMENTATIONS restricts initialisation to
  # only the listed instrumentation libraries, ignoring all others.
  it 'simple_load_with_desired_instrument_only' do
    result = run_in_subprocess('OTEL_RUBY_ENABLED_INSTRUMENTATIONS' => 'net_http')

    _(result[:error]).must_be_nil
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
    _(result[:instrumentation_names]).wont_include 'OpenTelemetry::Instrumentation::Rake'
  end

  describe 'metrics and logs sdk' do
    # Verifies that opentelemetry-metrics-sdk is loaded and the global meter_provider
    # is replaced with the full SDK implementation rather than the no-op default.
    it 'loads_metrics_sdk' do
      result = run_in_subprocess

      _(result[:error]).must_be_nil
      _(result[:meter_provider_class]).must_equal 'OpenTelemetry::SDK::Metrics::MeterProvider'
    end

    # Verifies that opentelemetry-logs-sdk is loaded and the global logger_provider
    # is replaced with the full SDK implementation rather than the no-op default.
    it 'loads_logs_sdk' do
      result = run_in_subprocess

      _(result[:error]).must_be_nil
      _(result[:logger_provider_class]).must_equal 'OpenTelemetry::SDK::Logs::LoggerProvider'
    end
  end

  describe 'signal data' do
    # Verifies that the TracerProvider can record a span end-to-end: creates a
    # tracer, opens a span with a custom attribute, and confirms the finished span
    # is captured by an in-memory exporter with the correct name and attribute.
    it 'captures_trace_span' do
      result = run_in_subprocess(
        { 'OTEL_TRACES_EXPORTER' => 'none', 'OTEL_METRICS_EXPORTER' => 'none', 'OTEL_LOGS_EXPORTER' => 'none' },
        { inspect_signals: true }
      )

      _(result[:error]).must_be_nil
      _(result[:spans]).wont_be_empty
      span = result[:spans].first
      _(span[:name]).must_equal 'test-span'
      _(span[:attributes]['test.key']).must_equal 'test.value'
    end

    # Verifies that the MeterProvider can record a counter measurement end-to-end:
    # creates a counter, adds a value with attributes, pulls the metric reader, and
    # confirms the data point is captured with the correct value and attributes.
    it 'captures_metric_counter' do
      result = run_in_subprocess(
        { 'OTEL_TRACES_EXPORTER' => 'none', 'OTEL_METRICS_EXPORTER' => 'none', 'OTEL_LOGS_EXPORTER' => 'none' },
        { inspect_signals: true }
      )

      _(result[:error]).must_be_nil
      _(result[:metrics]).wont_be_empty
      metric = result[:metrics].find { |m| m[:name] == 'test.counter' }
      _(metric).wont_be_nil
      data_point = metric[:data_points].first
      _(data_point[:value]).must_equal 3
      _(data_point[:attributes]['env']).must_equal 'test'
    end

    # Verifies that the LoggerProvider can emit a log record end-to-end: obtains a
    # logger, emits a record with a severity and body, and confirms the record is
    # captured by an in-memory exporter with the correct body and severity text.
    it 'captures_log_record' do
      result = run_in_subprocess(
        { 'OTEL_TRACES_EXPORTER' => 'none', 'OTEL_METRICS_EXPORTER' => 'none', 'OTEL_LOGS_EXPORTER' => 'none' },
        { inspect_signals: true }
      )

      _(result[:error]).must_be_nil
      _(result[:logs]).wont_be_empty
      log = result[:logs].first
      _(log[:body]).must_equal 'test log message'
      _(log[:severity_text]).must_equal 'INFO'
    end
  end

  describe 'check_for_bundled_otel_gems' do
    # Verifies that no warning is emitted when the user's Gemfile contains only
    # non-OpenTelemetry gems, since there is no conflict to report.
    it 'emits no warning when there are no opentelemetry gems in the bundle' do
      result = run_in_subprocess({}, dep_names: %w[rack faraday])

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_be_empty
    end

    # Verifies that a warning naming the conflicting gems is emitted when the
    # Gemfile contains OpenTelemetry gems, and that non-OTel gems are not mentioned.
    it 'emits a warning listing detected opentelemetry gems' do
      otel_gems = %w[opentelemetry-sdk opentelemetry-instrumentation-net_http rack]
      result = run_in_subprocess({}, dep_names: otel_gems)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_include '[OpenTelemetry] WARNING'
      _(result[:warning_output]).must_include 'opentelemetry-instrumentation-net_http'
      _(result[:warning_output]).must_include 'opentelemetry-sdk'
      _(result[:warning_output]).wont_include 'rack'
    end

    # Verifies that a Bundler error during the gem-list check is silently swallowed
    # when debug mode is off, so the application still starts cleanly.
    it 'emits no warning when Bundler.definition raises and debug mode is off' do
      result = run_in_subprocess({}, raise_error: true)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_be_empty
    end

    # Verifies that the same Bundler error is surfaced as a warning when debug mode
    # is enabled, including the original error message for easier diagnosis.
    it 'emits a warning when Bundler.definition raises and debug mode is on' do
      result = run_in_subprocess({ 'OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG' => 'true' }, raise_error: true)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_include '[OpenTelemetry] WARNING: Unable to check Gemfile'
      _(result[:warning_output]).must_include 'simulated bundler error'
    end
  end
end
