# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'opentelemetry-api'
  gem 'opentelemetry-instrumentation-base'
  gem 'opentelemetry-instrumentation-elasticsearch'
  gem 'opentelemetry-sdk'
  gem 'elasticsearch'
  gem 'pry-nav'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-elasticsearch'
require 'elasticsearch'
require 'pry-nav'
# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Elasticsearch'
end

client = Elasticsearch::Client.new(log: false, ssl: { verify: false }).tap do |client|
  client.instance_variable_set(:"@verified", true)
end

client.search q: 'test'

client.bulk(
  body: [{
    index: { _index: 'users', data: { name: 'Fernando' } }
  }]
)

client.index(
  index: 'foo',
  body: { name: 'Fernando' }
)
