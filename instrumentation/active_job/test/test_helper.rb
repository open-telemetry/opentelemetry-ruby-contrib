# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
ENV['OTEL_LOG_LEVEL'] ||= 'fatal'

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'
require 'opentelemetry-instrumentation-active_job'
require 'minitest/autorun'

class TestJob < ActiveJob::Base
  def perform; end
end

class RetryJob < ActiveJob::Base
  retry_on StandardError, wait: 0, attempts: 2

  def perform
    raise StandardError, 'from retry job'
  end
end

class DiscardJob < ActiveJob::Base
  class DiscardError < StandardError; end
  discard_on DiscardError

  def perform
    raise DiscardError, 'discard me'
  end
end

class ExceptionJob < ActiveJob::Base
  def perform
    raise StandardError, 'This job raises an exception'
  end
end

class BaggageJob < ActiveJob::Base
  def perform
    OpenTelemetry::Trace.current_span['success'] = OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class PositionalOnlyArgsJob < ActiveJob::Base
  def perform(arg1, arg2 = 'default'); end
end

class KeywordOnlyArgsJob < ActiveJob::Base
  def perform(keyword2:, keyword1: 'default'); end
end

class MixedArgsJob < ActiveJob::Base
  def perform(arg1, arg2, keyword2:, keyword1: 'default'); end
end

class CallbacksJob < TestJob
  class << self
    attr_accessor :context_before, :context_after
  end

  def initialize(*)
    self.class.context_before = self.class.context_after = nil
    super
  end

  before_perform(prepend: true) do
    self.class.context_before = OpenTelemetry::Trace.current_span.context
  end

  after_perform do
    self.class.context_after = OpenTelemetry::Trace.current_span.context
  end
end

class RescueFromJob < ActiveJob::Base
  class RescueFromError < StandardError; end

  rescue_from RescueFromError do
    # do nothing
  end

  def perform
    raise RescueFromError, 'I was handled by rescue_from'
  end
end

ActiveJob::Base.queue_adapter = :inline
ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  c.add_span_processor span_processor
end
