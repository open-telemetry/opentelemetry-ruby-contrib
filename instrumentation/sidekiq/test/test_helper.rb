# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_job'

require 'minitest/autorun'
require 'minitest/reporters'
require 'rspec/mocks/minitest_integration'
require 'sidekiq/testing'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('7.0.0')
  require 'helpers/mock_loader_for_7.0'
elsif Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('6.5.0')
  require 'helpers/mock_loader_for_6.5'
else
  require 'helpers/mock_loader'
end

# speed up tests that rely on empty queues
Sidekiq::BasicFetch::TIMEOUT = if Gem.loaded_specs['sidekiq'].version < Gem::Version.new('6.5.0')
                                 # Redis 4.8 has trouble with float timeouts given as positional arguments
                                 1
                               else
                                 0.1
                               end

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end

module LoadedMetricsFeatures
  OTEL_METRICS_API_LOADED = !Gem.loaded_specs['opentelemetry-metrics-api'].nil?
  OTEL_METRICS_SDK_LOADED = !Gem.loaded_specs['opentelemetry-metrics-sdk'].nil?

  extend self

  def api_loaded?
    OTEL_METRICS_API_LOADED
  end

  def sdk_loaded?
    OTEL_METRICS_SDK_LOADED
  end
end

# NOTE: this isn't currently used, but it may be useful to fully reset state between tests
def reset_meter_provider
  return unless LoadedMetricsFeatures.sdk_loaded?

  resource = OpenTelemetry.meter_provider.resource
  OpenTelemetry.meter_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: resource)
  OpenTelemetry.meter_provider.add_metric_reader(METRICS_EXPORTER)
end

def reset_metrics_exporter
  return unless LoadedMetricsFeatures.sdk_loaded?

  METRICS_EXPORTER.pull
  METRICS_EXPORTER.reset
end

if LoadedMetricsFeatures.sdk_loaded?
  METRICS_EXPORTER = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(METRICS_EXPORTER)
end

module ConditionalEvaluation
  def self.included(base)
    base.extend(self)
  end

  def self.prepended(base)
    base.extend(self)
  end

  def with_metrics_sdk
    yield if LoadedMetricsFeatures.sdk_loaded?
  end

  # FIXME: unclear if this is ever needed
  def without_metrics_sdk
    yield unless LoadedMetricsFeatures.sdk_loaded?
  end

  def it(desc = 'anonymous', with_metrics_sdk: false, without_metrics_sdk: false, &block)
    return super(desc, &block) unless with_metrics_sdk || without_metrics_sdk

    raise ArgumentError, 'without_metrics_sdk and with_metrics_sdk must be mutually exclusive' if without_metrics_sdk && with_metrics_sdk

    return if with_metrics_sdk && !LoadedMetricsFeatures.sdk_loaded?
    return if without_metrics_sdk && LoadedMetricsFeatures.sdk_loaded?

    super(desc, &block)
  end
end

Minitest::Spec.prepend(ConditionalEvaluation)

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
