# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka/patches/async_producer'

describe OpenTelemetry::Instrumentation::RubyKafka::Patches::AsyncProducer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:kafka) { Kafka.new(["abc:123"]) }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:producer) { double("producer", shutdown: true, produce: nil) }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer('test-tracer') }

  before(:each) do
    allow(kafka).to receive(:producer).and_return(producer)

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'produce' do
    it 'adds headers to producer.produce call and forwards all other args' do
      tracer.in_span('test') do |span|
        async_producer = kafka.async_producer(delivery_threshold: 1000)
        create_time = Time.now
        async_producer.produce('hello',
          key: "wat",
          headers: { "foo" => "bar" },
          partition: 1,
          partition_key: "ok",
          topic: topic,
          create_time: create_time)
        async_producer.deliver_messages
        expect(producer).to have_received(:produce).with(
          'hello',
          key: "wat",
          partition: 1,
          partition_key: "ok",
          create_time: create_time,
          topic: topic,
          headers: {
            "foo" => "bar",
            "traceparent" => "00-#{span.context.hex_trace_id}-#{span.context.hex_span_id}-01"
          })
      end
    end
  end
end unless ENV['OMIT_SERVICES']
