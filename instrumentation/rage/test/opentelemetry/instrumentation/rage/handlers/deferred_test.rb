# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../../lib/opentelemetry/instrumentation/rage/handlers/deferred'

describe OpenTelemetry::Instrumentation::Rage::Handlers::Deferred do
  subject { OpenTelemetry::Instrumentation::Rage::Handlers::Deferred }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  let(:task_class) { Class.new }
  let(:task_context) { {} }

  let(:result) { double(error?: false) }

  let(:finished_spans) { EXPORTER.finished_spans }
  let(:task_span) { finished_spans.first }

  before do
    instrumentation.install({})
    EXPORTER.reset
    stub_const('MyTask', task_class)
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '.create_enqueue_span' do
    it 'creates a span' do
      subject.create_enqueue_span(task_class:, task_context:) { result }

      _(finished_spans.size).must_equal(1)

      _(task_span.name).must_equal('MyTask enqueue')
      _(task_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
      _(task_span.kind).must_equal(:producer)

      _(task_span.attributes['messaging.system']).must_equal('rage.deferred')
      _(task_span.attributes['messaging.operation.type']).must_equal('publish')
      _(task_span.attributes['messaging.destination.name']).must_equal('MyTask')
      _(task_span.attributes['code.function.name']).must_equal('MyTask.enqueue')
    end

    it 'stores the context' do
      subject.create_enqueue_span(task_class:, task_context:) { result }
      _(task_context.key?('traceparent')).must_equal(true)
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        subject.create_enqueue_span(task_class:, task_context:) { result }

        _(task_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
        _(task_span.events.first.name).must_equal 'exception'
        _(task_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end
    end
  end

  describe '.create_perform_span' do
    let(:task) { double(meta: task_metadata) }
    let(:task_metadata) { double(attempts: 0, retrying?: false) }

    it 'creates a span' do
      subject.create_perform_span(task_class:, task:, task_context:) { result }

      _(finished_spans.size).must_equal(1)

      _(task_span.name).must_equal('MyTask perform')
      _(task_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
      _(task_span.kind).must_equal(:consumer)

      _(task_span.attributes['messaging.system']).must_equal('rage.deferred')
      _(task_span.attributes['messaging.operation.type']).must_equal('process')
      _(task_span.attributes['messaging.destination.name']).must_equal('MyTask')
      _(task_span.attributes['code.function.name']).must_equal('MyTask#perform')
      _(task_span.attributes['messaging.message.delivery_attempt']).must_be_nil

      _(task_span.links.nil?).must_equal(true)
    end

    describe 'with retries' do
      let(:task_metadata) { double(attempts: 3, retrying?: true) }

      it 'adds the retries attribute to the span' do
        subject.create_perform_span(task_class:, task:, task_context:) { result }

        _(task_span.attributes['messaging.system']).must_equal('rage.deferred')
        _(task_span.attributes['messaging.operation.type']).must_equal('process')
        _(task_span.attributes['messaging.destination.name']).must_equal('MyTask')
        _(task_span.attributes['code.function.name']).must_equal('MyTask#perform')
        _(task_span.attributes['messaging.message.delivery_attempt']).must_equal(3)
      end
    end

    describe 'with root span' do
      let(:task_span) { finished_spans.last }

      before do
        instrumentation.tracer.in_span('test span') do |_span|
          OpenTelemetry.propagation.inject(task_context)
        end
      end

      it 'links to root span' do
        subject.create_perform_span(task_class:, task:, task_context:) { result }

        _(task_span.links.nil?).must_equal(false)
        _(task_span.links.first).must_be_instance_of(OpenTelemetry::Trace::Link)
      end
    end

    describe 'with baggage' do
      before do
        context = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')

        OpenTelemetry::Context.with_current(context) do
          OpenTelemetry.propagation.inject(task_context)
        end
      end

      it 'propagates baggage' do
        subject.create_perform_span(task_class:, task:, task_context:) do
          _(OpenTelemetry::Baggage.value('testing_baggage')).must_equal('it_worked')
          result
        end
      end
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        subject.create_perform_span(task_class:, task:, task_context:) { result }

        _(task_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
        _(task_span.events.first.name).must_equal 'exception'
        _(task_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end
    end
  end
end
