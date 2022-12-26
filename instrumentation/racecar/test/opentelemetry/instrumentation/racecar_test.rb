# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'securerandom'

require 'racecar/cli'
require_relative '../../../lib/opentelemetry/instrumentation/racecar'

describe OpenTelemetry::Instrumentation::Racecar do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Racecar::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:host) { ENV.fetch('TEST_KAFKA_HOST', '127.0.0.1') }
  let(:port) { ENV.fetch('TEST_KAFKA_PORT', 29_092) }

  def wait_for_spans(count)
    Timeout.timeout(60) do
      sleep 0.1 while exporter.finished_spans.size < count
    end
  end

  let(:consumer_class) do
    klass = Class.new(Racecar::Consumer)
    klass.define_method(:process, &process_method)
    klass.subscribes_to(topic_name)
    stub_const('TestConsumer', klass)
  end

  let(:tracer) do
    OpenTelemetry.tracer_provider.tracer('test-tracer')
  end

  def produce(messages)
    config = { 'bootstrap.servers': "#{host}:#{port}" }
    producer = Rdkafka::Config.new(config).producer
    producer.delivery_callback = ->(_) {}

    producer_messages.map do |msg|
      tracer.in_span("#{msg[:topic]} send", kind: :producer) do
        msg[:headers] ||= {}
        OpenTelemetry.propagation.inject(msg[:headers])
        producer.produce(**msg)
      end
    end.each(&:wait)

    producer.close
  end

  let(:racecar) do
    Racecar.config.brokers = ["#{host}:#{port}"]
    Racecar.config.pause_timeout = 0 # fail fast and exit
    Racecar.config.load_consumer_class(consumer_class)
    Racecar::Runner.new(consumer_class.new, config: Racecar.config, logger: Logger.new(STDOUT), instrumenter: Racecar.instrumenter)
  end

  def run_racecar(racecar)
    Thread.new do
      Thread.current[:racecar] = racecar
      racecar.run
    rescue RuntimeError => e
      raise e unless e.message == 'oops'
    end
  end

  def stop_racecar(thread)
    thread[:racecar].stop
    thread.join(60)
  end

  let(:topic_name) do
    rand_hash = SecureRandom.hex(10)
    "consumer-patch-trace-#{rand_hash}"
  end

  before do
    # Clear spans
    exporter.reset

    instrumentation.install

    produce(producer_messages)

    @racecar_thread = run_racecar(racecar)
    wait_for_spans(expected_spans)
  end

  after do
    stop_racecar(@racecar_thread)
  end

  describe '#process' do
    describe 'when the consumer runs and publishes acks' do
      let(:process_method) do
        lambda do |message|
          produce(
            'message seen',
            topic: "ack-#{message.topic}"
          )
          deliver!
        end
      end

      let(:producer_messages) do
        [{
          topic: topic_name,
          payload: 'never gonna',
          key: 'Key 1'
        }, {
          topic: topic_name,
          payload: 'give you up',
          key: 'Key 2'
        }]
      end

      let(:expected_spans) { 6 }

      it 'traces each message and traces publishing' do
        process_spans = spans.select { |s| s.name == "#{topic_name} process" }
        racecar_send_spans = spans.select { |s| s.name == "ack-#{topic_name} send" }

        # First pair for send and process spans
        first_process_span = process_spans[0]
        _(first_process_span.name).must_equal("#{topic_name} process")
        _(first_process_span.kind).must_equal(:consumer)
        _(first_process_span.attributes['messaging.destination']).must_equal(topic_name)
        _(first_process_span.attributes['messaging.kafka.partition']).wont_be_nil

        first_process_span_link = first_process_span.links[0]
        linked_span_context = first_process_span_link.span_context

        linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
        _(linked_send_span.name).must_equal("#{topic_name} send")
        _(linked_send_span.trace_id).must_equal(first_process_span.trace_id)
        _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

        # first racecar ack span
        first_send_span = racecar_send_spans[0]
        _(first_send_span.name).must_equal("ack-#{topic_name} send")
        _(first_send_span.kind).must_equal(:producer)
        _(first_send_span.instrumentation_library.name).must_equal('OpenTelemetry::Instrumentation::Racecar')
        _(first_send_span.parent_span_id).must_equal(first_process_span.span_id)
        _(first_send_span.trace_id).must_equal(first_process_span.trace_id)

        # Second pair of send and process spans
        second_process_span = process_spans[1]
        _(second_process_span.name).must_equal("#{topic_name} process")
        _(second_process_span.kind).must_equal(:consumer)

        second_process_span_link = second_process_span.links[0]
        linked_span_context = second_process_span_link.span_context

        linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
        _(linked_send_span.name).must_equal("#{topic_name} send")
        _(linked_send_span.trace_id).must_equal(second_process_span.trace_id)
        _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

        # second racecar ack span
        second_send_span = racecar_send_spans[1]
        _(second_send_span.name).must_equal("ack-#{topic_name} send")
        _(second_send_span.kind).must_equal(:producer)
        _(second_send_span.instrumentation_library.name).must_equal('OpenTelemetry::Instrumentation::Racecar')
        _(second_send_span.parent_span_id).must_equal(second_process_span.span_id)
        _(second_send_span.trace_id).must_equal(second_process_span.trace_id)
      end
    end

    describe 'for an erroring consumer' do
      let(:process_method) do
        lambda do |_message|
          raise 'oops'
        end
      end

      let(:producer_messages) do
        [{
          topic: topic_name,
          payload: 'never gonna',
          key: 'Key 1'
        }]
      end

      let(:expected_spans) { 2 }

      it 'can consume and publish a message' do
        process_spans = spans.select { |s| s.name == "#{topic_name} process" }

        # First pair for send and process spans
        first_process_span = process_spans[0]
        _(first_process_span.name).must_equal("#{topic_name} process")
        _(first_process_span.kind).must_equal(:consumer)
        _(first_process_span.attributes['messaging.destination']).must_equal(topic_name)
        _(first_process_span.attributes['messaging.kafka.partition']).wont_be_nil

        first_process_span_link = first_process_span.links[0]
        linked_span_context = first_process_span_link.span_context

        linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
        _(linked_send_span.name).must_equal("#{topic_name} send")
        _(linked_send_span.trace_id).must_equal(first_process_span.trace_id)
        _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

        event = first_process_span.events.first
        _(event.name).must_equal('exception')
        _(event.attributes['exception.type']).must_equal('RuntimeError')
        _(event.attributes['exception.message']).must_equal('oops')
      end
    end
  end
end
