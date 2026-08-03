# frozen_string_literal: true

require 'dotenv'
Dotenv.load(File.expand_path('../.env', __dir__))
Dotenv.load(File.expand_path('.env', __dir__))

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end

port = Env.fetch('TEST_REDIS_PORT', '6379')
password = Env.fetch('REDIS_PASSWORD', 'passw0rd')
redis = Redis.new(port: port, password: password)
redis.set('mykey', 'hello world')
