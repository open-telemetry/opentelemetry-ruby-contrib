# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'net/http'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
end

Net::HTTP.get(URI('http://example.com'))

OpenTelemetry.tracer_provider.tracer.in_span('activate') do
  Net::HTTP.get(URI('http://example.com'))
end

OpenTelemetry.tracer_provider.tracer.in_span('deactivate') do
  OpenTelemetry::Common::Utilities.untraced do
    Net::HTTP.get(URI('http://example.com'))
  end
end
