# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'rack/test'
require 'test_helpers/app_config'

require 'opentelemetry-instrumentation-rails'

# Global opentelemetry-sdk setup
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use_all
  c.add_span_processor span_processor
end

# Create a globally available Rails app, this should be used in test unless
# specifically testing behaviour with different initialization configs.
DEFAULT_RAILS_APP = AppConfig.initialize_app
Rails.application = DEFAULT_RAILS_APP
