# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'AutoInstrumentation' do
  let(:auto_instrumentation_path) { File.expand_path('../lib/auto-instrumentation.rb', __dir__) }

  before do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
    ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = nil
    ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] = nil
  end

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

  it 'simple_load_with_net_http_disabled' do
    result = run_in_subprocess('OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED' => 'false')

    _(result[:error]).must_be_nil
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Rake'
    _(result[:instrumentation_names]).wont_include 'OpenTelemetry::Instrumentation::Net::HTTP'
  end

  it 'simple_load_with_desired_instrument_only' do
    result = run_in_subprocess('OTEL_RUBY_ENABLED_INSTRUMENTATIONS' => 'net_http')

    _(result[:error]).must_be_nil
    _(result[:instrumentation_names]).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
    _(result[:instrumentation_names]).wont_include 'OpenTelemetry::Instrumentation::Rake'
  end

  describe 'check_for_bundled_otel_gems' do
    it 'emits no warning when there are no opentelemetry gems in the bundle' do
      result = run_in_subprocess({}, dep_names: %w[rack faraday])

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_be_empty
    end

    it 'emits a warning listing detected opentelemetry gems' do
      otel_gems = %w[opentelemetry-sdk opentelemetry-instrumentation-net_http rack]
      result = run_in_subprocess({}, dep_names: otel_gems)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_include '[OpenTelemetry] WARNING'
      _(result[:warning_output]).must_include 'opentelemetry-instrumentation-net_http'
      _(result[:warning_output]).must_include 'opentelemetry-sdk'
      _(result[:warning_output]).wont_include 'rack'
    end

    it 'emits no warning when Bundler.definition raises and debug mode is off' do
      result = run_in_subprocess({}, raise_error: true)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_be_empty
    end

    it 'emits a warning when Bundler.definition raises and debug mode is on' do
      result = run_in_subprocess({ 'OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG' => 'true' }, raise_error: true)

      _(result[:error]).must_be_nil
      _(result[:warning_output]).must_include '[OpenTelemetry] WARNING: Unable to check Gemfile'
      _(result[:warning_output]).must_include 'simulated bundler error'
    end
  end
end
