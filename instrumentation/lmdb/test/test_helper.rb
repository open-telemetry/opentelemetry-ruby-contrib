# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'webmock/minitest'

# Set OTEL_SEMCONV_STABILITY_OPT_IN based on appraisal name
gemfile = ENV.fetch('BUNDLE_GEMFILE', '')
if gemfile.include?('stable')
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database'
elsif gemfile.include?('dup')
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database/dup'
end

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end
