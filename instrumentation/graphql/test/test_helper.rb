# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end

# Hack that allows us to reset the internal state of the tracer to test installation
module SchemaTestPatches
  # Reseting @graphql_definition is needed for tests running against version `1.9.x`
  # Other variables are used by ~> 2.0.19
  def _reset_tracer_for_testing
    %w[own_tracers trace_class tracers graphql_definition].each do |ivar|
      remove_instance_variable("@#{ivar}") if instance_variable_defined?("@#{ivar}")
    end
  end
end

GraphQL::Schema.extend(SchemaTestPatches)
