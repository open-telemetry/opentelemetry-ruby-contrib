# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

ENV['OTEL_SERVICE_NAME'] ||= 'otel-active-job-demo'
require 'rubygems'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'activejob', '~> 7.0.0', require: 'active_job'
  gem 'opentelemetry-instrumentation-active_job', path: '../'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-exporter-otlp'
end

ENV['OTEL_LOG_LEVEL'] ||= 'fatal'
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  at_exit { OpenTelemetry.tracer_provider.shutdown }
end

class FailingJob < ::ActiveJob::Base
  queue_as :demo
  def perform
    raise 'this job failed'
  end
end

class FailingRetryJob < ::ActiveJob::Base
  queue_as :demo

  retry_on StandardError, attempts: 2, wait: 0
  def perform
    raise 'this job failed'
  end
end

class RetryJob < ::ActiveJob::Base
  queue_as :demo

  retry_on StandardError, attempts: 3, wait: 0
  def perform
    if executions < 3
      raise 'this job failed'
    else
      puts <<~EOS

      --------------------------------------------------
       Done Retrying!
      --------------------------------------------------

      EOS
    end
  end
end

class DiscardJob < ::ActiveJob::Base
  queue_as :demo

  class DiscardError < StandardError; end

  discard_on DiscardError

  def perform
    raise DiscardError, 'this job failed'
  end
end

EXAMPLE_TRACER = OpenTelemetry.tracer_provider.tracer('activejob-example', '1.0')

class TestJob < ::ActiveJob::Base
  def perform
    EXAMPLE_TRACER.in_span("custom span") do
      puts <<~EOS

      --------------------------------------------------
       The computer is doing some work, beep beep boop.
      --------------------------------------------------

      EOS
    end
  end
end

class DoItNowJob < ::ActiveJob::Base
  def perform
    $stderr.puts <<~EOS

    --------------------------------------------------
     Called with perform_now!
    --------------------------------------------------

    EOS
  end
end

class BatchJob < ::ActiveJob::Base
  def perform
    TestJob.perform_later
    FailingJob.perform_later
    FailingRetryJob.perform_later
    RetryJob.perform_later
    DiscardJob.perform_later
  end
end

::ActiveJob::Base.queue_adapter = :async

EXAMPLE_TRACER.in_span('run-jobs') do
  DoItNowJob.perform_now
  BatchJob.perform_later
end

sleep 5 # allow the job to complete
