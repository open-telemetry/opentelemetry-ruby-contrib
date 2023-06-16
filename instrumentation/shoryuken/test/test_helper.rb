# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

require 'helpers/mock_loader'

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end

# Silence Actibe Job logging noise
# ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

# class SimpleJobWithActiveJob < ActiveJob::Base
#   self.queue_adapter = :shoryuken

#   def perform(*args); end
# end

# Test jobs
# class SimpleEnqueueingJob
#   include Shoryuken::Worker
#   shoryuken_options body_parser: JSON, queue: 'default', auto_delete: true

#   def perform(sqs_msg, payload)
#     SimpleJob.perform_async
#   end
# end

class SimpleJob
  include Shoryuken::Worker
  shoryuken_options body_parser: JSON, queue: 'default', auto_delete: false

  def perform(sqs_msg, payload); end
end

# class BaggageTestingJob
#   include Shoryuken::Worker
#   shoryuken_options body_parser: JSON, queue: 'default', auto_delete: true

#   def perform(*args)
#     OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
#   end
# end

class ExceptionTestingJob
  include Shoryuken::Worker
  shoryuken_options body_parser: JSON, queue: 'default', auto_delete: true

  def perform(*args)
    raise 'a little hell'
  end
end

module Shoryuken
  module CLI
  # Hack to have shoryuken think it's a server context
  # see https://github.com/ruby-shoryuken/shoryuken/blob/f24db5422ef6869c4a556c134a27b4259027e7b8/lib/shoryuken/options.rb#L151
  end
end
