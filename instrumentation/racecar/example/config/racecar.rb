# frozen_string_literal: true

Racecar.configure do |config|
  # Each config variable can be set using a writer attribute.
  host = ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' }
  port = ENV.fetch('TEST_KAFKA_PORT') { 29_092 }
  config.brokers = ["#{host}:#{port}"]
end
