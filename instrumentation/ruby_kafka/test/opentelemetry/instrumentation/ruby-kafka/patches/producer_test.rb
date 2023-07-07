# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka/patches/producer'

describe OpenTelemetry::Instrumentation::RubyKafka::Patches::Producer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer('test-tracer') }

  let(:host) { ENV.fetch('TEST_KAFKA_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_KAFKA_PORT', 29_092) }

  let(:kafka) { Kafka.new(["#{host}:#{port}"], client_id: 'opentelemetry-kafka-test') }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:async_topic) { "async-#{topic}" }
  let(:producer) { kafka.producer }
  let(:consumer) { kafka.consumer(group_id: SecureRandom.uuid, fetcher_max_queue_size: 1) }
  let(:async_producer) { kafka.async_producer(delivery_threshold: 1000) }

  before do
    kafka.create_topic(topic)
    kafka.create_topic(async_topic)
    consumer.subscribe(async_topic)

    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Clean up
    producer.shutdown
    async_producer.shutdown
    consumer.stop
    kafka.close
  end

  describe 'tracing' do
    it 'traces sync produce calls' do
      producer.produce('hello', topic: topic)
      producer.deliver_messages

      _(spans.first.name).must_equal("#{topic} send")
      _(spans.first.kind).must_equal(:producer)

      _(spans.first.attributes['messaging.system']).must_equal('kafka')
      _(spans.first.attributes['messaging.destination']).must_equal(topic)
    end

    it 'traces async produce calls' do
      async_producer.produce('hello async', topic: async_topic)
      async_producer.deliver_messages

      # Wait for the async calls to produce spans
      wait_for(error_message: 'Max wait time exceeded for async producer') { EXPORTER.finished_spans.size.positive? }

      _(spans.first.name).must_equal("#{async_topic} send")
      _(spans.first.kind).must_equal(:producer)

      _(spans.first.attributes['messaging.system']).must_equal('kafka')
      _(spans.first.attributes['messaging.destination']).must_equal(async_topic)
    end

    it 'ignores headers when context is set' do
      span_id = 'b7ad6b7169203331'
      tracer.in_span('wat') do |sp|
        producer.produce('hello', topic: topic, headers: { 'traceparent' => "00-0af7651916cd43dd8448eb211c80319c-#{span_id}-01" })
        producer.deliver_messages

        _(spans.first.parent_span_id).must_equal(sp.context.span_id)
        _(spans.first.trace_id).must_equal(sp.context.trace_id)
      end
    end

    it 'propagates context when tracing async produce calls' do
      tracer.in_span('wat') do |sp|
        async_producer.produce('hello async', topic: async_topic)
        async_producer.deliver_messages

        # Wait for the async calls to produce spans
        wait_for(error_message: 'Max wait time exceeded for async producer') { EXPORTER.finished_spans.size.positive? }

        _(spans.first.trace_id).must_equal(sp.context.trace_id)
        _(spans.first.parent_span_id).must_equal(sp.context.span_id)
      end
    end

    it 'does propagate context for nonrecording spans' do
      sp = OpenTelemetry::Trace.non_recording_span(OpenTelemetry::Trace::SpanContext::INVALID)
      OpenTelemetry::Trace.with_span(sp) do
        async_producer.produce('hello async', topic: async_topic)
        async_producer.deliver_messages
        _(EXPORTER.finished_spans.size).must_equal(0)
      end
    end
  end
end unless ENV['OMIT_SERVICES']
