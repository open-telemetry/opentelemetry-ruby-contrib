# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'AutoInstrumentation' do
  let(:auto_instrumentation_path) { File.expand_path('../lib/opentelemetry-auto-instrumentation.rb', __dir__) }

  before do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
    ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = nil
    ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] = nil
  end

  after do
    ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'] = nil
    ENV['OTEL_RUBY_INSTRUMENTATION_NET_HTTP_ENABLED'] = nil
    ENV['OTEL_RUBY_RESOURCE_DETECTORS'] = nil
    ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = nil
    ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] = nil
  end

  def run_in_subprocess(env_vars = {})
    # Run the test in a subprocess to avoid contaminating the test environment
    read_pipe, write_pipe = IO.pipe

    pid = fork do
      read_pipe.close
      env_vars.each { |key, value| ENV[key] = value }

      ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = 'false'
      begin
        # Load the auto-instrumentation library
        load auto_instrumentation_path
        Bundler.require

        # Get tracer provider information
        tracer_provider = OpenTelemetry.tracer_provider
        resource = tracer_provider.instance_variable_get(:@resource)
        resource_attributes = resource.instance_variable_get(:@attributes)
        registry = tracer_provider.instance_variable_get(:@registry)
        instrumentation_names = registry.map { |entry| entry.first.name }

        # Serialize and send results back to parent
        result = Marshal.dump({
                                tracer_provider_class: tracer_provider.class.name,
                                resource_attributes: resource_attributes,
                                instrumentation_names: instrumentation_names
                              })
        write_pipe.write(result)
      rescue StandardError => e
        error_result = Marshal.dump({ error: e.message, backtrace: e.backtrace })
        write_pipe.write(error_result)
      ensure
        write_pipe.close
        exit!(0)
      end
    end

    write_pipe.close
    result_data = read_pipe.read
    read_pipe.close
    Process.wait(pid)

    # rubocop:disable Security/MarshalLoad
    Marshal.load(result_data)
    # rubocop:enable Security/MarshalLoad
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

  it 'simple_load_with_additional_resource' do
    result = run_in_subprocess('OTEL_RUBY_RESOURCE_DETECTORS' => 'container')

    _(result[:error]).must_be_nil
    _(result[:resource_attributes].key?('container.id')).must_equal true
    _(result[:resource_attributes]['telemetry.sdk.name']).must_equal 'opentelemetry'
    _(result[:resource_attributes]['telemetry.sdk.language']).must_equal 'ruby'
  end
end
