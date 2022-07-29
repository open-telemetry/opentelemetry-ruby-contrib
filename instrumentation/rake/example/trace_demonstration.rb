# frozen_string_literal: true

require 'rake'
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'opentelemetry-api'
  gem 'opentelemetry-instrumentation-base'
  gem 'opentelemetry-instrumentation-rake'
  gem 'opentelemetry-sdk'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-rake'

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rake'
end

Rake::Task.define_task(:test_rake_instrumentation)

Rake::Task[:test_rake_instrumentation].invoke
Rake::Task[:test_rake_instrumentation].execute
