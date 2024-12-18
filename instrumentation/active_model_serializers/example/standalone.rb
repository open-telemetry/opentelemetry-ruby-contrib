# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'active_model_serializers'
  gem 'opentelemetry-api'
  gem 'opentelemetry-common'
  gem 'opentelemetry-instrumentation-active_model_serializers', path: '../'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-exporter-otlp'
end

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'active_model_serializers_example'
  c.use_all
end

# without Rails and the Railtie automation, must manually trigger
# instrumentation subscription after SDK is configured
OpenTelemetry::Instrumentation::ActiveModelSerializers.subscribe

at_exit do
  OpenTelemetry.tracer_provider.shutdown
end

ExampleAppTracer = OpenTelemetry.tracer_provider.tracer('example_app')

class TestModel
  include ActiveModel::API
  include ActiveModel::Serialization

  attr_accessor :name

  def attributes
    { 'name' => nil,
      'screaming_name' => nil }
  end

  def screaming_name
    ExampleAppTracer.in_span('screaming_name transform') do |span|
      name.upcase
    end
  end
end

model = TestModel.new(name: 'test object')
serialized_model = ActiveModelSerializers::SerializableResource.new(model).serializable_hash

puts "\n*** The serialized object: #{serialized_model}"
