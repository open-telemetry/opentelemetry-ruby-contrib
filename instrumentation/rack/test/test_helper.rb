# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)
require 'rack/events'
require 'opentelemetry-instrumentation-rack'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end

# Simulates a request in a separate Fiber, similar to how Rage behaves
# We explicitly pass along the parent context because frameworks
# should do this in their own instrumentation to correctly
# propagate context.
#
# See: https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/2130
class WrapInFiber
  def initialize(app)
    @app = app
  end

  def call(env)
    parent_context = OpenTelemetry::Context.current
    Fiber.new do
      OpenTelemetry::Context.attach(parent_context)
      @app.call(env)
    end.resume
  end
end
