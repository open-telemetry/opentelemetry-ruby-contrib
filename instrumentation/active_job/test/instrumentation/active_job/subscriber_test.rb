# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Subscriber do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  # Technically these are the defaults. But ActiveJob seems to act oddly if you re-install
  # the instrumentation over and over again - so we manipulate instance variables to
  # reset between tests, and that means we should set the defaults here.
  let(:config) { { propagation_style: :link, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:publish_span) { spans.find { |s| s.name == 'default publish' } }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }
  let(:discard_span) { spans.find { |s| s.name == 'discard.active_job' } }

  before do
    OpenTelemetry::Instrumentation::ActiveJob::Subscriber.uninstall
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

  describe 'perform_later' do
    it 'traces enqueuing and processing the job' do
      TestJob.perform_later

      _(publish_span).wont_be_nil
      _(process_span).wont_be_nil
    end
  end

  describe 'perform_now' do
    it 'only traces processing the job' do
      TestJob.perform_now

      _(publish_span).must_be_nil
      _(process_span).wont_be_nil
      _(process_span.attributes['code.namespace']).must_equal('TestJob')
    end
  end

  describe 'compatibility' do
    it 'works with positional args' do
      _(PositionalOnlyArgsJob.perform_now('arg1')).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with keyword args' do
      _(KeywordOnlyArgsJob.perform_now(keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with mixed args' do
      _(MixedArgsJob.perform_now('arg1', 'arg2', keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end
  end

  describe 'exception handling' do
    it 'sets span status to error' do
      _ { ExceptionJob.perform_later }.must_raise StandardError, 'This job raises an exception'

      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(process_span.status.description).must_equal 'This job raises an exception'

      _(process_span.events.first.name).must_equal 'exception'
      _(process_span.events.first.attributes['exception.type']).must_equal 'StandardError'
      _(process_span.events.first.attributes['exception.message']).must_equal 'This job raises an exception'
    end

    it 'sets discard span status to error' do
      DiscardJob.perform_later

      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(process_span.status.description).must_equal 'discard me'

      _(discard_span.events.first.name).must_equal 'exception'
      _(discard_span.events.first.attributes['exception.type']).must_equal 'DiscardJob::DiscardError'
      _(discard_span.events.first.attributes['exception.message']).must_equal 'discard me'
    end
  end

  describe 'span kind' do
    it 'sets correct span kinds for inline jobs' do
      begin
        ActiveJob::Base.queue_adapter.shutdown
      rescue StandardError
        nil
      end
      ActiveJob::Base.queue_adapter = :inline

      TestJob.perform_later

      _(publish_span.kind).must_equal(:producer)
      _(process_span.kind).must_equal(:consumer)
    end

    it 'sets correct span kinds for all other jobs' do
      TestJob.perform_later

      _(publish_span.kind).must_equal(:producer)
      _(process_span.kind).must_equal(:consumer)
    end
  end

  describe 'attributes' do
    describe 'net.transport' do
      it 'is sets correctly for inline jobs' do
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['net.transport']).must_equal('inproc')
        end
      end

      it 'is set correctly for async jobs' do
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['net.transport']).must_equal('inproc')
        end
      end
    end

    describe 'messaging.active_job.priority' do
      it 'is unset for unprioritized jobs' do
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.priority']).must_be_nil
        end
      end

      it 'is set for jobs with a priority' do
        TestJob.set(priority: 1).perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['rails.active_job.priority']).must_equal(1)
        end
      end
    end

    describe 'messaging.active_job.scheduled_at' do
      it 'is set correctly for jobs that do wait in Rails 7.0 or older' do
        skip 'scheduled jobs behave differently in Rails 7.1 and newer' if ActiveJob.version < Gem::Version.new('7.1')

        job = TestJob.set(wait: 0.second).perform_later

        _(publish_span.attributes['rails.active_job.scheduled_at']).must_equal(job.scheduled_at.to_f)
        _(process_span.attributes['rails.active_job.scheduled_at']).must_equal(job.scheduled_at.to_f)
      end

      it 'is set correctly for jobs that do wait in Rails 7.1 and newer' do
        skip 'scheduled jobs behave differently in Rails 7.0 and older' if ActiveJob.version >= Gem::Version.new('7.1')

        job = TestJob.set(wait: 0.second).perform_later

        _(publish_span.attributes['rails.active_job.scheduled_at']).must_equal(job.scheduled_at.to_f)
        _(process_span.attributes['rails.active_job.scheduled_at']).must_be_nil
      end
    end

    describe 'messaging.system' do
      it 'is set correctly for the inline adapter' do
        begin
          ActiveJob::Base.queue_adapter.shutdown
        rescue StandardError
          nil
        end

        ActiveJob::Base.queue_adapter = :inline
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['messaging.system']).must_equal('inline')
        end
      end

      it 'is set correctly for the async adapter' do
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['messaging.system']).must_equal('async')
        end
      end
    end

    describe 'messaging.active_job.executions' do
      it 'is 1 for a normal job that does not retry in Rails 6 or earlier' do
        skip "ActiveJob #{ActiveJob.version} starts at 0 in newer versions" if ActiveJob.version >= Gem::Version.new('7')
        TestJob.perform_now
        _(process_span.attributes['rails.active_job.execution.counter']).must_equal(1)
      end

      it 'is 0 for a normal job that does not retry in Rails 7 or later' do
        skip "ActiveJob #{ActiveJob.version} starts at 1 for older versions" if ActiveJob.version < Gem::Version.new('7')
        TestJob.perform_now
        _(process_span.attributes['rails.active_job.execution.counter']).must_equal(0)
      end

      it 'tracks correctly for jobs that do retry in Rails 6 or earlier' do
        skip "ActiveJob #{ActiveJob.version} starts at 0 in newer versions" if ActiveJob.version >= Gem::Version.new('7')
        begin
          RetryJob.perform_later
        rescue StandardError
          nil
        end

        executions = spans.filter { |s| s.kind == :consumer }.map { |s| s.attributes['rails.active_job.execution.counter'] }.compact.max
        _(executions).must_equal(2) # total of 3 runs. The initial and 2 retries.
      end

      it 'tracks correctly for jobs that do retry in Rails 7 or later' do
        skip "ActiveJob #{ActiveJob.version} starts at 1 in older versions" if ActiveJob.version < Gem::Version.new('7')
        begin
          RetryJob.perform_later
        rescue StandardError
          nil
        end

        executions = spans.filter { |s| s.kind == :consumer }.map { |s| s.attributes['rails.active_job.execution.counter'] }.compact.max
        _(executions).must_equal(1)
      end
    end

    describe 'messaging.active_job.provider_job_id' do
      it 'is empty for a job that do not sets provider_job_id' do
        TestJob.perform_now
        _(process_span.attributes['messaging.active_job.provider_job_id']).must_be_nil
      end

      it 'sets the correct value if provider_job_id is provided' do
        job = TestJob.perform_later
        _(process_span.attributes['rails.active_job.provider_job_id']).must_equal(job.provider_job_id)
      end
    end

    it 'generally sets other attributes as expected' do
      job = TestJob.perform_later

      [publish_span, process_span].each do |span|
        _(span.attributes['code.namespace']).must_equal('TestJob')
        _(span.attributes['messaging.destination_kind']).must_equal('queue')
        _(span.attributes['messaging.system']).must_equal('async')
        _(span.attributes['messaging.message_id']).must_equal(job.job_id)
      end
    end
  end

  describe 'span_naming option' do
    describe 'when queue - default' do
      it 'names spans according to the job queue' do
        TestJob.set(queue: :foo).perform_later
        publish_span = exporter.finished_spans.find { |s| s.name == 'foo publish' }
        _(publish_span).wont_be_nil

        process_span = exporter.finished_spans.find { |s| s.name == 'foo process' }
        _(process_span).wont_be_nil
      end
    end

    describe 'when job_class' do
      let(:config) { { propagation_style: :link, span_naming: :job_class } }

      it 'names span according to the job class' do
        TestJob.set(queue: :foo).perform_later

        publish_span = exporter.finished_spans.find { |s| s.name == 'TestJob publish' }
        _(publish_span).wont_be_nil

        process_span = exporter.finished_spans.find { |s| s.name == 'TestJob process' }
        _(process_span).wont_be_nil
      end
    end
  end

  describe 'propagation_style option' do
    describe 'link - default' do
      # The inline job adapter executes the job immediately upon enqueuing it
      # so we can't actually use that in these tests - the actual Context.current at time
      # of execution *will* be the context where the job was enqueued, because rails
      # ends up doing job.around_enqueue { job.around_perform { block } } inline.
      it 'creates span links in separate traces' do
        TestJob.perform_later

        _(publish_span.trace_id).wont_equal(process_span.trace_id)

        _(process_span.total_recorded_links).must_equal(1)
        _(process_span.links[0].span_context.trace_id).must_equal(publish_span.trace_id)
        _(process_span.links[0].span_context.span_id).must_equal(publish_span.span_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end

        _(publish_span.trace_id).wont_equal(process_span.trace_id)

        _(process_span.total_recorded_links).must_equal(1)
        _(process_span.links[0].span_context.trace_id).must_equal(publish_span.trace_id)
        _(process_span.links[0].span_context.span_id).must_equal(publish_span.span_id)

        _(process_span.attributes['success']).must_equal(true)
      end
    end

    describe 'when configured to do parent/child spans' do
      let(:config) { { propagation_style: :child, span_naming: :queue } }

      it 'creates a parent/child relationship' do
        TestJob.perform_later

        _(process_span.total_recorded_links).must_equal(0)

        _(publish_span.trace_id).must_equal(process_span.trace_id)
        _(process_span.parent_span_id).must_equal(publish_span.span_id)
      end

      it 'propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end
        _(process_span.total_recorded_links).must_equal(0)

        _(publish_span.trace_id).must_equal(process_span.trace_id)
        _(process_span.parent_span_id).must_equal(publish_span.span_id)
        _(process_span.attributes['success']).must_equal(true)
      end
    end

    describe 'when explicitly configure for no propagation' do
      let(:config) { { propagation_style: :none, span_naming: :queue } }

      it 'skips link creation and does not create parent/child relationship' do
        TestJob.perform_later

        _(process_span.total_recorded_links).must_equal(0)

        _(publish_span.trace_id).wont_equal(process_span.trace_id)
        _(process_span.parent_span_id).wont_equal(publish_span.span_id)
      end

      it 'still propagates baggage' do
        ctx = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')
        OpenTelemetry::Context.with_current(ctx) do
          BaggageJob.perform_later
        end

        _(process_span.total_recorded_links).must_equal(0)

        _(publish_span.trace_id).wont_equal(process_span.trace_id)
        _(process_span.parent_span_id).wont_equal(publish_span.span_id)
        _(process_span.attributes['success']).must_equal(true)
      end
    end
  end

  describe 'active_job callbacks' do
    it 'makes the tracing context available in before_perform callbacks' do
      skip "ActiveJob #{ActiveJob.version} subscribers do not include timing information for callbacks" if ActiveJob.version < Gem::Version.new('7')
      CallbacksJob.perform_now

      _(CallbacksJob.context_before).wont_be_nil
      _(CallbacksJob.context_before).must_be :valid?
    end

    it 'makes the tracing context available in after_perform callbacks' do
      skip "ActiveJob #{ActiveJob.version} subscribers do not include timing information for callbacks" if ActiveJob.version < Gem::Version.new('7')
      CallbacksJob.perform_now

      _(CallbacksJob.context_after).wont_be_nil
      _(CallbacksJob.context_after).must_be :valid?
    end
  end
end
