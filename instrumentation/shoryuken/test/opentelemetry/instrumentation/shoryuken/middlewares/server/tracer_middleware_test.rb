# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../../lib/opentelemetry/instrumentation/shoryuken'
require_relative '../../../../../../lib/opentelemetry/instrumentation/shoryuken/middlewares/server/tracer_middleware'

describe OpenTelemetry::Instrumentation::Shoryuken::Middlewares::Server::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Shoryuken::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:enqueuer_span) { spans.first }
  let(:job_span) { spans.last }
  let(:root_span) { spans.find { |s| s.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID } }
  let(:config) { {} }
  let(:queue_name) { 'default' }
  let(:sqs_msg) do
    double(
      Shoryuken::Message,
      queue_url: queue_name,
      body: '{"test" : 1}',
      message_attributes: {
        'shoryuken_class' => { string_value: worker_class.name }
      },
      message_id: SecureRandom.uuid,
      receipt_handle: SecureRandom.uuid
    )
  end
  let(:sqs_client) { Aws::SQS::Client.new(stub_responses: true) }
  let(:worker_class) { SimpleJob }

  before do
    allow(sqs_client).to receive(:get_queue_url).and_return(double(queue_url: 'https://sqs.fake.amazonaws.com/1/queue-name'))
    allow(sqs_msg).to receive(:[]).with('baggage')
    allow(sqs_msg).to receive(:[]).with('traceparent')
    instrumentation.install(config)
    exporter.reset
    Shoryuken::Client.sqs = sqs_client
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe 'enqueue spans' do
    it 'before performing any jobs' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'traces processing' do
      Shoryuken::Processor.process(queue_name, sqs_msg)

      _(exporter.finished_spans.size).must_equal 1

      _(job_span.name).must_equal "#{queue_name} process"
      _(job_span.kind).must_equal :consumer
      _(job_span.attributes['messaging.system']).must_equal 'shoryuken'
      _(job_span.attributes['messaging.shoryuken.job_class']).must_equal worker_class.name
      _(job_span.attributes['messaging.message_id']).must_equal sqs_msg.message_id
      _(job_span.attributes['messaging.destination']).must_equal 'default'
      _(job_span.attributes['messaging.destination_kind']).must_equal 'queue'
      _(job_span.attributes['messaging.operation']).must_equal 'process'
    end

    describe 'when enqueued with Active Job' do
      let(:worker_class) { SimpleJobWithActiveJob }

      it 'traces when enqueued with Active Job' do
        Shoryuken::Processor.process(queue_name, sqs_msg)

        _(job_span.attributes['messaging.system']).must_equal 'shoryuken'
        _(job_span.attributes['messaging.shoryuken.job_class']).must_equal worker_class.name
        _(job_span.attributes['messaging.message_id']).must_equal sqs_msg.message_id
        _(job_span.attributes['messaging.destination']).must_equal 'default'
        _(job_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(job_span.attributes['messaging.operation']).must_equal 'process'
      end
    end

    describe 'when span_naming is job_class' do
      let(:config) { { span_naming: :job_class } }

      it 'uses the job class name for the span name' do
        Shoryuken::Processor.process(queue_name, sqs_msg)

        _(job_span.name).must_equal("#{worker_class} process")
      end
    end

    describe 'when worker raises exception' do
      let(:worker_class) { ExceptionTestingJob }

      it 'records exceptions' do
        _(-> { Shoryuken::Processor.process(queue_name, sqs_msg) }).must_raise(RuntimeError)

        ev = job_span.events
        _(ev[0].attributes['exception.type']).must_equal('RuntimeError')
        _(ev[0].attributes['exception.message']).must_equal('a little hell')
        _(ev[0].attributes['exception.stacktrace']).wont_be_nil
      end
    end
  end
end
