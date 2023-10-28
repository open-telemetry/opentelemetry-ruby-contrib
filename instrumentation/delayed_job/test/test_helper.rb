# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

# These are dependencies that delayed job assumes are already loaded
# We are compensating for that here in this test... that is a smell
# NoMethodError: undefined method `extract_options!' for [#<ActiveJobPayload:0x0000000108bf5d48>, {}]:Array
# delayed_job-4.1.11/lib/delayed/backend/job_preparer.rb:7:in `initialize'0
require 'active_support/core_ext/array/extract_options'

require 'opentelemetry-instrumentation-delayed_job'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end

gem_dir = Gem::Specification.find_by_name('delayed_job').gem_dir
require "#{gem_dir}/spec/delayed/backend/test"

Delayed::Worker.backend = Delayed::Backend::Test::Job
