# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

# Set OTEL_SEMCONV_STABILITY_OPT_IN based on appraisal name
gemfile = ENV.fetch('BUNDLE_GEMFILE', '')
if gemfile.include?('stable')
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database'
elsif gemfile.include?('dup')
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database/dup'
end

require 'opentelemetry-instrumentation-aws_sdk'

require 'minitest/autorun'
require 'webmock/minitest'
require 'rspec/mocks/minitest_integration'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::AwsSdk'
  c.add_span_processor span_processor
end

class TestHelper
  class << self
    def telemetry_plugin?(service)
      m = ::Aws.const_get(service).const_get(:Client)
      Aws.const_defined?('Plugins::Telemetry') &&
        m.plugins.include?(Aws::Plugins::Telemetry)
    end

    def match_span_attrs(expected_attrs, span, expect)
      expected_attrs.each do |key, value|
        expect._(span.attributes[key]).must_equal(value)
      end
    end

    def semconv_old?
      gemfile = ENV.fetch('BUNDLE_GEMFILE', '')
      gemfile.include?('old') || (!gemfile.include?('stable') && !gemfile.include?('dup'))
    end

    def semconv_stable?
      ENV.fetch('BUNDLE_GEMFILE', '').include?('stable')
    end

    def semconv_dup?
      ENV.fetch('BUNDLE_GEMFILE', '').include?('dup')
    end
  end
end
