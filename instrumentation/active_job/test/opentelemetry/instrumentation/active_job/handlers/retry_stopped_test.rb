# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/active_job'

describe 'OpenTelemetry::Instrumentation::ActiveJob::Handlers::RetryStopped' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  let(:config) { { propagation_style: :link, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:publish_span) { spans.find { |s| s.name == 'default publish' } }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }
  let(:retry_span) { spans.find { |s| s.name == 'retry_stopped.active_job' } }

  before do
    OpenTelemetry::Instrumentation::ActiveJob::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)
    ActiveJob::Base.queue_adapter = :async
    ActiveJob::Base.queue_adapter.immediate = true

    exporter.reset
  end

  after do
    begin
      ActiveJob::Base.queue_adapter.shutdown
    rescue StandardError
      nil
    end
    ActiveJob::Base.queue_adapter = :inline
  end

  describe 'attributes' do
    describe 'active_job.executions' do
      it 'tracks correctly for jobs that do retry in Rails 6 or earlier' do
        skip "ActiveJob #{ActiveJob.version} starts at 0 in newer versions" if ActiveJob.version >= Gem::Version.new('7')
        _ { RetryJob.perform_later }.must_raise StandardError

        executions = spans.filter { |s| s.kind == :consumer }.map { |s| s.attributes['rails.active_job.execution.counter'] }.compact.max
        _(executions).must_equal(2) # total of 3 runs. The initial and 2 retries.
      end

      it 'tracks correctly for jobs that do retry in Rails 7 or later' do
        skip "ActiveJob #{ActiveJob.version} starts at 1 in older versions" if ActiveJob.version < Gem::Version.new('7')
        _ { RetryJob.perform_later }.must_raise StandardError

        executions = spans.filter { |s| s.kind == :consumer }.map { |s| s.attributes['rails.active_job.execution.counter'] }.compact.max
        _(executions).must_equal(1)
      end

      it 'records retry errors' do
        _ { RetryJob.perform_later }.must_raise StandardError

        _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(process_span.status.description).must_equal 'Unexpected ActiveJob Error StandardError'

        _(retry_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
        _(retry_span.status.description).must_equal 'Unexpected ActiveJob Error StandardError'
        _(retry_span.events.first.name).must_equal 'exception'
        _(retry_span.events.first.attributes['exception.type']).must_equal 'StandardError'
        _(retry_span.events.first.attributes['exception.message']).must_equal 'from retry job'
      end
    end
  end
end
