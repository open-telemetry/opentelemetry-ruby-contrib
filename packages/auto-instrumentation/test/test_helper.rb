# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rake'
require 'minitest'
require 'minitest/autorun'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-all'
require 'opentelemetry-test-helpers'
require 'opentelemetry/resource/detector'
require 'net/http'

# Helper function that execute the auto-instrumentation in isolated env
def run_in_subprocess(env_vars = {}, opts = {})
  dep_names = opts[:dep_names]
  raise_error = opts.fetch(:raise_error, false)

  read_pipe, write_pipe = IO.pipe

  pid = fork do
    read_pipe.close
    env_vars.each { |key, value| ENV[key] = value }
    ENV['OTEL_RUBY_REQUIRE_BUNDLER'] = 'false'

    begin
      load auto_instrumentation_path

      require 'stringio'
      stderr_capture = StringIO.new
      old_stderr = $stderr
      $stderr = stderr_capture

      result = {}

      # check the log msg based on different condition
      if !dep_names.nil? || raise_error
        fake_dep = Struct.new(:name)
        fake_deps = (dep_names || []).map { |n| fake_dep.new(n) }

        if raise_error
          # Suppress the Ruby "method redefined" warning that define_singleton_method
          # produces when overwriting Bundler's existing :definition method.
          old_verbose = $VERBOSE
          $VERBOSE = nil
          Bundler.define_singleton_method(:definition) { raise StandardError, 'simulated bundler error' }
        else
          fake_definition = Object.new
          fake_definition.define_singleton_method(:dependencies) { fake_deps }
          old_verbose = $VERBOSE
          $VERBOSE = nil
          Bundler.define_singleton_method(:definition) { fake_definition }
        end
        $VERBOSE = old_verbose

        OTelBundlerPatch::OTelInitializer.check_for_bundled_otel_gems
      else
        Bundler.require

        tracer_provider = OpenTelemetry.tracer_provider
        resource = tracer_provider.instance_variable_get(:@resource)
        resource_attributes = resource.instance_variable_get(:@attributes)
        registry = tracer_provider.instance_variable_get(:@registry)
        instrumentation_names = registry.map { |entry| entry.first.name }

        result.merge!(
          tracer_provider_class: tracer_provider.class.name,
          resource_attributes: resource_attributes,
          instrumentation_names: instrumentation_names
        )
      end

      $stderr = old_stderr
      result[:warning_output] = stderr_capture.string
      write_pipe.write(Marshal.dump(result))
    rescue StandardError => e
      $stderr = old_stderr if defined?(old_stderr)
      error_result = Marshal.dump({ error: e.message, backtrace: e.backtrace, warning_output: defined?(stderr_capture) ? stderr_capture.string : '' })
      write_pipe.write(error_result)
    ensure
      $stderr = old_stderr if defined?(old_stderr)
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
