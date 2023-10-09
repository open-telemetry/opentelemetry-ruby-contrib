# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Mappers::Attribute do
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

  it 'uses trace semantic conventions and Rails specific attributes' do
    job = TestJob.perform_later

    [publish_span, process_span].each do |span|
      _(span.attributes['code.namespace']).must_equal('TestJob')
      _(span.attributes['messaging.system']).must_equal('async')
      _(span.attributes['messaging.destination']).must_equal('default')
      _(span.attributes['messaging.message.id']).must_equal(job.job_id)
      _(span.attributes['rails.active_job.priority']).must_be_nil
    end

    _(publish_span.attributes['rails.active_job.provider_job_id']).must_equal('')
    _(process_span.attributes['rails.active_job.provider_job_id']).must_equal(job.provider_job_id)
  end

  it 'tracks the job priority' do
    TestJob.set(priority: 5).perform_later

    [publish_span, process_span].each do |span|
      _(span.attributes['rails.active_job.priority']).must_equal(5)
    end
  end

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

  it 'is unset for jobs that do not specify a wait time' do
    TestJob.perform_later

    [publish_span, process_span].each do |span|
      _(span.attributes['rails.active_job.scheduled_at']).must_be_nil
    end
  end

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
end
