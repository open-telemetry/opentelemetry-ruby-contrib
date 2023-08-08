# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'sidekiq/testing'

if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('7.0.0')
  require 'helpers/mock_loader_for_7.0'
elsif Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('6.5.0')
  require 'helpers/mock_loader_for_6.5'
else
  require 'helpers/mock_loader'
end

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end

# Sidekiq redis configuration
ENV['TEST_REDIS_HOST'] ||= '127.0.0.1'
ENV['TEST_REDIS_PORT'] ||= '16379'

redis_url = "redis://#{ENV['TEST_REDIS_HOST']}:#{ENV['TEST_REDIS_PORT']}/0"

Sidekiq.configure_server do |config|
  config.redis = { password: 'passw0rd', url: redis_url }

  if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('6.5.0')
    config.queues = ['default']
    config.concurrency = 1
  end
end

Sidekiq.configure_client do |config|
  config.redis = { password: 'passw0rd', url: redis_url }
end

# Silence Actibe Job logging noise
ActiveJob::Base.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)

class SimpleJobWithActiveJob < ActiveJob::Base
  self.queue_adapter = :sidekiq

  def perform(*args); end
end

# Test jobs
class SimpleEnqueueingJob
  include Sidekiq::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Sidekiq::Worker

  def perform; end
end

class BaggageTestingJob
  include Sidekiq::Worker

  def perform(*args)
    OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class ExceptionTestingJob
  include Sidekiq::Worker

  def perform(*args)
    raise 'a little hell'
  end
end

module Frontkiq
  class SweetClientMiddleware
    # Use middleware base classes that come with Sidekiq >= 7.0.0
    include ::Sidekiq::ClientMiddleware if defined?(::Sidekiq::ClientMiddleware)

    # see https://github.com/sidekiq/sidekiq/wiki/Middleware
    def call(_job_class_or_string, _job, _queue, _redis_pool)
      yield
    end
  end

  class SweetServerMiddleware
    # Use middleware base classes that come with Sidekiq >= 7.0.0
    include ::Sidekiq::ServerMiddleware if defined?(::Sidekiq::ServerMiddleware)

    # see https://github.com/sidekiq/sidekiq/wiki/Middleware
    def call(_job_instance, _job_payload, _queue_name)
      yield
    end
  end
end
