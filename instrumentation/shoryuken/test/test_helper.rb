# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'
require 'shoryuken/extensions/active_job_adapter'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end

Shoryuken.configure_server do |config|
end

Shoryuken.configure_client do |config|
end

# Silence Actibe Job logging noise
ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

class SimpleJobWithActiveJob < ActiveJob::Base
  self.queue_adapter = :shoryuken

  def perform(*args); end
end

# Test jobs
class SimpleEnqueueingJob
  include Shoryuken::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Shoryuken::Worker

  def perform; end
end

class BaggageTestingJob
  include Shoryuken::Worker

  def perform(*args)
    OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class ExceptionTestingJob
  include Shoryuken::Worker

  def perform(*args)
    raise 'a little hell'
  end
end
