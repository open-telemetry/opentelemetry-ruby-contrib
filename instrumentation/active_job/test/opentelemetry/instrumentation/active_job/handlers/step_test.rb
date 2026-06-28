# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/active_job'

require 'active_job/continuation/test_helper' if defined?(ActiveJob::Continuable)

describe OpenTelemetry::Instrumentation::ActiveJob::Handlers::Step do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  let(:config) { { propagation_style: :link, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }
  let(:step_spans) { spans.select { |s| s.name.start_with?('first_step', 'second_step', 'process_items') } }

  before do
    skip 'Requires ActiveJob::Continuable (Rails 8.1+)' unless defined?(ActiveJob::Continuable)

    OpenTelemetry::Instrumentation::ActiveJob::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)

    exporter.reset
  end

  describe 'basic step tracing' do
    it 'creates a span for each step' do
      ContinuableJob.perform_now

      _(step_spans.length).must_equal 2
    end

    it 'names spans using the step name' do
      ContinuableJob.perform_now

      first_step_span = spans.find { |s| s.name == 'first_step ContinuableJob' }
      second_step_span = spans.find { |s| s.name == 'second_step ContinuableJob' }

      _(first_step_span).wont_be_nil
      _(second_step_span).wont_be_nil
    end

    it 'creates step spans as children of the process span' do
      ContinuableJob.perform_now

      step_spans.each do |step_span|
        _(step_span.parent_span_id).must_equal process_span.span_id
      end
    end
  end

  describe 'step attributes' do
    it 'includes the step name' do
      ContinuableJob.perform_now

      first_step_span = spans.find { |s| s.name == 'first_step ContinuableJob' }
      _(first_step_span.attributes['messaging.active_job.step.name']).must_equal 'first_step'
    end

    it 'includes state as started for first execution' do
      ContinuableJob.perform_now

      first_step_span = spans.find { |s| s.name == 'first_step ContinuableJob' }
      _(first_step_span.attributes['messaging.active_job.step.state']).must_equal 'started'
    end

    it 'includes standard messaging attributes' do
      ContinuableJob.perform_now

      first_step_span = spans.find { |s| s.name == 'first_step ContinuableJob' }
      _(first_step_span.attributes['code.namespace']).must_equal 'ContinuableJob'
      _(first_step_span.attributes['messaging.system']).must_equal 'active_job'
      _(first_step_span.attributes['messaging.destination']).must_equal 'default'
    end

    it 'does not mark the step as interrupted' do
      ContinuableJob.perform_now

      first_step_span = spans.find { |s| s.name == 'first_step ContinuableJob' }
      assert_nil(first_step_span.attributes['messaging.active_job.step.result'])
    end
  end

  describe 'cursor tracking' do
    it 'includes the cursor value when present' do
      ContinuableWithCursorJob.perform_now

      step_span = spans.find { |s| s.name == 'process_items ContinuableWithCursorJob' }
      _(step_span.attributes['messaging.active_job.step.cursor']).must_equal '3'
    end
  end

  describe 'interrupted step' do
    before do
      singleton_class.include ActiveJob::Continuation::TestHelper
      ActiveJob::Base.queue_adapter = :test
    end

    after do
      ActiveJob::Base.queue_adapter = :inline
    end

    it 'does not record an error on the step span' do
      ContinuableWithCursorJob.perform_later
      interrupt_job_during_step(ContinuableWithCursorJob, :process_items, cursor: 2) { perform_enqueued_jobs }

      step_span = spans.find { |s| s.name == 'process_items ContinuableWithCursorJob' }
      _(step_span.status.code).must_equal OpenTelemetry::Trace::Status::OK
      _(step_span.events).must_be_nil
    end

    it 'marks the step as interrupted' do
      ContinuableWithCursorJob.perform_later
      interrupt_job_during_step(ContinuableWithCursorJob, :process_items, cursor: 2) { perform_enqueued_jobs }

      step_span = spans.find { |s| s.name == 'process_items ContinuableWithCursorJob' }
      _(step_span.attributes['messaging.active_job.step.result']).must_equal 'interrupted'
    end
  end
end
