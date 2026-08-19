# frozen_string_literal: true

require 'dotenv'
Dotenv.load('.env', '../.env')

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end

port = ENV.fetch('TEST_REDIS_PORT', '6379')
password = ENV.fetch('REDIS_PASSWORD', 'passw0rd')
redis = Redis.new(port: port, password: password)
redis.set('mykey', 'hello world')
