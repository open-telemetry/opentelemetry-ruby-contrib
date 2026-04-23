# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'logger'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'opentelemetry-instrumentation-action_pack'
require 'minitest/autorun'
require 'rack/test'
require 'test_helpers/app_config'

# Global opentelemetry-sdk setup
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::ActionPack'
  c.add_span_processor span_processor
end

def with_sampler(sampler)
  previous_sampler = OpenTelemetry.tracer_provider.sampler
  OpenTelemetry.tracer_provider.sampler = sampler
  yield
ensure
  OpenTelemetry.tracer_provider.sampler = previous_sampler
end
