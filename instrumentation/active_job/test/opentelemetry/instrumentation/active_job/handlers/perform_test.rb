# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Handlers::Perform do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  let(:config) { { propagation_style: :link, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:publish_span) { spans.find { |s| s.name == 'default publish' } }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }

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

  describe 'exception handling' do
    it 'sets span status to error' do
      _ { ExceptionJob.perform_later }.must_raise StandardError, 'This job raises an exception'

      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(process_span.status.description).must_equal 'Unexpected ActiveJob Error StandardError'

      _(process_span.events.first.name).must_equal 'exception'
      _(process_span.events.first.attributes['exception.type']).must_equal 'StandardError'
      _(process_span.events.first.attributes['exception.message']).must_equal 'This job raises an exception'
    end

    it 'captures errors that were handled by rescue_from in versions earlier than Rails 7' do
      skip 'rescue_from jobs behave differently in Rails 7 and newer' if ActiveJob.version >= Gem::Version.new('7')
      RescueFromJob.perform_later

      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(process_span.status.description).must_equal 'Unexpected ActiveJob Error RescueFromJob::RescueFromError'

      _(process_span.events.first.name).must_equal 'exception'
      _(process_span.events.first.attributes['exception.type']).must_equal 'RescueFromJob::RescueFromError'
      _(process_span.events.first.attributes['exception.message']).must_equal 'I was handled by rescue_from'
    end

    it 'ignores errors that were handled by rescue_from in versions of Rails 7 or newer' do
      skip 'rescue_from jobs behave differently in Rails 7 and newer' if ActiveJob.version < Gem::Version.new('7')
      RescueFromJob.perform_later

      _(process_span.status.code).must_equal OpenTelemetry::Trace::Status::OK

      _(process_span.events).must_be_nil
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
    describe 'active_job.priority' do
      it 'is unset for unprioritized jobs' do
        TestJob.perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.message.priority']).must_be_nil
        end
      end

      it 'is set for jobs with a priority' do
        TestJob.set(priority: 1).perform_later

        [publish_span, process_span].each do |span|
          _(span.attributes['messaging.active_job.message.priority']).must_equal('1')
        end
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
