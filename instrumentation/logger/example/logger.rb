# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'logger'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-logs-sdk'
  gem 'opentelemetry-instrumentation-logger', path: '../'
end

require 'opentelemetry/sdk'
require 'opentelemetry-logs-sdk'
require 'opentelemetry-instrumentation-logger'
require 'logger'

# Don't attempt to export traces, Logger instrumentation only emits logs.
ENV['OTEL_TRACES_EXPORTER'] ||= 'none'
ENV['OTEL_LOGS_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Logger'
end

at_exit do
  OpenTelemetry.logger_provider.shutdown
end

logger = Logger.new(STDOUT)
logger.debug('emerald ash borer')
