# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../../lib/opentelemetry/instrumentation/rage/handlers/events'

describe OpenTelemetry::Instrumentation::Rage::Handlers::Events do
  subject { OpenTelemetry::Instrumentation::Rage::Handlers::Events }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  let(:finished_spans) { EXPORTER.finished_spans }
  let(:event_span) { finished_spans.first }

  before do
    instrumentation.install({})
    EXPORTER.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '.create_publisher_span' do
    let(:event_class) { Class.new }
    let(:event) { event_class.new }

    before do
      stub_const('MyEvent', event_class)
    end

    describe 'with active span' do
      it 'creates a span' do
        instrumentation.tracer.in_span('test span') do
          subject.create_publisher_span(event:) {}
        end

        _(finished_spans.size).must_equal(2)

        _(event_span.name).must_equal('MyEvent publish')
        _(event_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
        _(event_span.kind).must_equal(:producer)

        _(event_span.attributes['messaging.system']).must_equal('rage.events')
        _(event_span.attributes['messaging.operation.type']).must_equal('publish')
        _(event_span.attributes['messaging.destination.name']).must_equal('MyEvent')
      end

      it 'yields control' do
        yielded = false

        subject.create_publisher_span(event:) do
          yielded = true
        end

        _(yielded).must_equal(true)
      end
    end

    describe 'without active span' do
      it 'does not create a span' do
        subject.create_publisher_span(event:) {}
        _(finished_spans.size).must_equal(0)
      end

      it 'yields control' do
        yielded = false

        subject.create_publisher_span(event:) do
          yielded = true
        end

        _(yielded).must_equal(true)
      end
    end
  end

  describe '.create_subscriber_span' do
    let(:subscriber_class) do
      Class.new do
        def self.deferred?; end
      end
    end
    let(:subscriber) { subscriber_class.new }

    let(:event_class) { Class.new }
    let(:event) { event_class.new }

    let(:result) { double(error?: false) }

    before do
      stub_const('MySubscriber', subscriber_class)
      stub_const('MyEvent', event_class)
    end

    describe 'with a synchronous subscriber' do
      it 'creates a span' do
        subscriber_class.stub(:deferred?, -> { false }) do
          subject.create_subscriber_span(subscriber:, event:) { result }
        end

        _(finished_spans.size).must_equal(1)

        _(event_span.name).must_equal('MySubscriber process')
        _(event_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
        _(event_span.kind).must_equal(:consumer)

        _(event_span.attributes['messaging.system']).must_equal('rage.events')
        _(event_span.attributes['messaging.operation.type']).must_equal('process')
        _(event_span.attributes['messaging.destination.name']).must_equal('MyEvent')
        _(event_span.attributes['code.function.name']).must_equal('MySubscriber#call')
      end

      describe 'with error' do
        let(:result) { double(error?: true, exception: RuntimeError.new) }

        it 'handles returned exceptions' do
          subject.create_subscriber_span(subscriber:, event:) { result }

          _(event_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
          _(event_span.events.first.name).must_equal 'exception'
          _(event_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
        end
      end
    end

    describe 'with an asynchronous subscriber' do
      it 'does not create a span' do
        subscriber_class.stub(:deferred?, -> { true }) do
          subject.create_subscriber_span(subscriber:, event:) {}
        end

        _(finished_spans.size).must_equal(0)
      end

      it 'yields control' do
        yielded = false

        subscriber_class.stub(:deferred?, -> { true }) do
          subject.create_subscriber_span(subscriber:, event:) do
            yielded = true
          end
        end

        _(yielded).must_equal(true)
      end
    end
  end
end
