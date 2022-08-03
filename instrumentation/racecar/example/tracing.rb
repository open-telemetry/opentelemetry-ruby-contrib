# frozen_string_literal: true

require 'active_support'
require 'opentelemetry/sdk'
require 'opentelemetry-instrumentation-racecar'

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Racecar'
end

host = ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' }
port = ENV.fetch('TEST_KAFKA_PORT') { 29_092 }
config = { "bootstrap.servers": "#{host}:#{port}" }
producer = Rdkafka::Config.new(config).producer
delivery_handles = []

topic_name = 'racecar-example-topic'

delivery_handles << producer.produce(
  topic: topic_name,
  payload: 'never gonna',
  key: 'Key 1'
)

delivery_handles << producer.produce(
  topic: topic_name,
  payload: 'give you up',
  key: 'Key 2'
)

delivery_handles.each(&:wait)

producer.close
