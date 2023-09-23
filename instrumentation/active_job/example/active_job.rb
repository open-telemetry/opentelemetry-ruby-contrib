# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'activejob', require: 'active_job'
  # gem 'opentelemetry-instrumentation-active_job', path: '../'
  gem 'opentelemetry-sdk'
end

require_relative '../lib/opentelemetry/instrumentation/active_job/subscriber'

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
OpenTelemetry::SDK.configure do |c|
  # c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  at_exit { OpenTelemetry.tracer_provider.shutdown }
end

class TestJob < ::ActiveJob::Base
  def perform
    puts <<~EOS

    --------------------------------------------------
     The computer is doing some work, beep beep boop.
    --------------------------------------------------

    EOS
  end
end

::ActiveJob::Base.queue_adapter = :async

TestJob.perform_later
sleep 0.1 # allow the job to complete
