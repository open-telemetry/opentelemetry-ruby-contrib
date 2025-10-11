# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'test_helpers/app_config'

EXPORTER = OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter.new
log_record_processor = OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(EXPORTER)
LOG_STREAM = StringIO.new
BROADCASTED_STREAM = StringIO.new

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_log_record_processor log_record_processor
end

# Create a globally available Rails app, this should be used in test unless
# specifically testing behaviour with different initialization configs.
DEFAULT_RAILS_APP = AppConfig.initialize_app
Rails.application = DEFAULT_RAILS_APP
