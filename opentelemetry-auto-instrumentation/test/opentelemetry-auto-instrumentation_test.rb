# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'ZeroCodeInstrumentation' do
  before do
    OpenTelemetry::TestHelpers.reset_opentelemetry
  end

  after do
    OTelBundlerPatch.send(:remove_const, :OTEL_INSTRUMENTATION_MAP)
    OTelBundlerPatch.send(:undef_method, :detect_resource_from_env)
    OTelBundlerPatch.send(:undef_method, :determine_enabled_instrumentation)
    OTelBundlerPatch.send(:undef_method, :require_otel)
    OTelBundlerPatch.send(:undef_method, :require)
    OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance_variable_get(:@instance).instance_variable_set(:@installed, false)
    OpenTelemetry::Instrumentation::Rake::Instrumentation.instance_variable_get(:@instance).instance_variable_set(:@installed, false)

    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
  end

  it 'simple_load_test' do
    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    _(OpenTelemetry.tracer_provider.class).must_equal OpenTelemetry::SDK::Trace::TracerProvider

    resource_attributes = OpenTelemetry.tracer_provider.instance_variable_get(:@resource).instance_variable_get(:@attributes)

    _(resource_attributes['service.name']).must_equal 'unknown_service'
    _(resource_attributes['telemetry.sdk.name']).must_equal 'opentelemetry'
    _(resource_attributes['telemetry.sdk.language']).must_equal 'ruby'
    _(resource_attributes.key?('container.id')).must_equal false

    registry = OpenTelemetry.tracer_provider.instance_variable_get(:@registry)

    _(registry.size).must_equal 2
  end

  it 'simple_load_with_net_http_disabled' do
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = 'false'

    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    registry = OpenTelemetry.tracer_provider.instance_variable_get(:@registry)

    _(registry.size).must_equal 1
    _(registry.first.first.name).must_equal 'OpenTelemetry::Instrumentation::Rake'

    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
  end

  it 'simple_load_with_desired_instrument_only' do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = 'net_http'

    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    registry = OpenTelemetry.tracer_provider.instance_variable_get(:@registry)

    _(registry.size).must_equal 1
    _(registry.first.first.name).must_equal 'OpenTelemetry::Instrumentation::Net::HTTP'
  end

  it 'simple_load_with_additional_resource' do
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = 'container'

    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    resource_attributes = OpenTelemetry.tracer_provider.instance_variable_get(:@resource).instance_variable_get(:@attributes)
    _(resource_attributes.key?('container.id')).must_equal true
    _(resource_attributes['telemetry.sdk.name']).must_equal 'opentelemetry'
    _(resource_attributes['telemetry.sdk.language']).must_equal 'ruby'

    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
  end
end
