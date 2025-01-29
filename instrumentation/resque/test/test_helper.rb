# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'

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

ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

redis_options = {}
redis_options[:password] = ENV['TEST_REDIS_PASSWORD'] || 'passw0rd'
redis_options[:host] = ENV['TEST_REDIS_HOST'] || '127.0.0.1'
redis_options[:port] = ENV['TEST_REDIS_PORT'] || '16379'
Resque.redis = redis_options

class DummyJob
  @queue = :super_urgent

  def self.perform(*args); end
end

class DummyJobWithActiveJob < ActiveJob::Base
  self.queue_adapter = :resque
  queue_as :super_urgent

  def perform(*args); end
end

class BaggageTestingJob
  @queue = :super_urgent

  def self.perform(*args)
    OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class ExceptionTestingJob
  @queue = :super_urgent

  def self.perform(*args)
    raise 'a little hell'
  end
end
