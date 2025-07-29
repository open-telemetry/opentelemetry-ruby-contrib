# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'AutoInstrumentation' do
  before do
    OpenTelemetry::TestHelpers.reset_opentelemetry
  end

  after do
    # Clean up constants and methods if they exist
    if defined?(OTelBundlerPatch::Initializer::OTEL_INSTRUMENTATION_MAP)
      OTelBundlerPatch::Initializer.send(:remove_const, :OTEL_INSTRUMENTATION_MAP)
    end

    if defined?(OTelBundlerPatch::Initializer)
      OTelBundlerPatch.send(:remove_const, :Initializer)
    end

    %i[require].each do |method|
      if OTelBundlerPatch.method_defined?(method)
        OTelBundlerPatch.send(:undef_method, method)
      end
    end    # Reset instrumentation installation state
    [
      OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation,
      OpenTelemetry::Instrumentation::Rake::Instrumentation
    ].each do |instrumentation|
      instance = instrumentation.instance_variable_get(:@instance)
      instance&.instance_variable_set(:@installed, false)
    end

    # Clean up environment variables
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
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
    instrumentation_names = registry.map { |entry| entry.first.name }.sort

    _(instrumentation_names).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
    _(instrumentation_names).must_include 'OpenTelemetry::Instrumentation::Rake'
  end

  it 'simple_load_with_net_http_disabled' do
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = 'false'

    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    registry = OpenTelemetry.tracer_provider.instance_variable_get(:@registry)
    instrumentation_names = registry.map { |entry| entry.first.name }

    _(instrumentation_names).must_include 'OpenTelemetry::Instrumentation::Rake'
    _(instrumentation_names).wont_include 'OpenTelemetry::Instrumentation::Net::HTTP'

    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
  end

  it 'simple_load_with_desired_instrument_only' do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = 'net_http'

    load './lib/opentelemetry-auto-instrumentation.rb'
    Bundler.require

    registry = OpenTelemetry.tracer_provider.instance_variable_get(:@registry)
    instrumentation_names = registry.map { |entry| entry.first.name }

    _(instrumentation_names).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
    _(instrumentation_names).wont_include 'OpenTelemetry::Instrumentation::Rake'
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
