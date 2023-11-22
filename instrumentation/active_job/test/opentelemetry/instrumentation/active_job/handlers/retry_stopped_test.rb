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
