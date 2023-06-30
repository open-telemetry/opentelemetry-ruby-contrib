# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

require 'helpers/mock_loader'
require 'shoryuken/extensions/active_job_adapter'

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end

# Silence Actibe Job logging noise
ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

class SimpleJobWithActiveJob < ActiveJob::Base
  queue_as :default
  include Shoryuken::Worker
  shoryuken_options body_parser: JSON, queue: 'default', auto_delete: false

  def perform(*args); end
end

class SimpleJob
  include Shoryuken::Worker
  shoryuken_options body_parser: JSON, queue: 'default', auto_delete: false

  def perform(sqs_msg, payload); end
end

class ExceptionTestingJob
  include Shoryuken::Worker
  shoryuken_options body_parser: JSON, queue: 'default', auto_delete: true

  def perform(*args)
    raise 'a little hell'
  end
end

module Shoryuken
  module CLI
  # Hack to signal to shoryuken it's running in a server context
  # see https://github.com/ruby-shoryuken/shoryuken/blob/f24db5422ef6869c4a556c134a27b4259027e7b8/lib/shoryuken/options.rb#L151
  end
end
