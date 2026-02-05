# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'kafka'
require 'active_support'

tracer = OpenTelemetry.tracer_provider.tracer('kafka demo')
exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: "http://jaeger:4318/v1/traces")
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
topic = Time.now.to_i.to_s

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(span_processor)
  c.service_name = "kafka-instrumentation-demo"
  c.use 'OpenTelemetry::Instrumentation::RubyKafka'
end

# Assumes kafka is available
kafka = Kafka.new(['kafka:9092', 'kafka:9092'], client_id: 'opentelemetry-ruby-demonstration')

# Instantiate a new producer.
producer = kafka.producer


# Add a message to the producer buffer synchronously
tracer.in_span("hello sync") do |span|
  producer.produce('sync example', topic: topic)
end


### ASYNC

# Add message to producer buffer

async_producer = kafka.async_producer(delivery_threshold: 1, delivery_interval: 0.001)

tracer.in_span("hello async") do |span|
  async_producer.produce('async example', topic: topic, headers: { foo: :bar }, create_time: Time.now)
end

producer.deliver_messages

# Process messages
count = 0
kafka.each_message(topic: topic) do |message|
  count += 1
  break if count == 2 # we only generate 2 messages
end
