# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'opentelemetry-api'
  gem 'opentelemetry-instrumentation-base'
  gem 'opentelemetry-instrumentation-httpx'
  gem 'opentelemetry-sdk'
  gem 'httpx'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-httpx'
require 'httpx'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::HTTPX'
end

# A basic HTTP example
HTTPX.get('https://github.com')
