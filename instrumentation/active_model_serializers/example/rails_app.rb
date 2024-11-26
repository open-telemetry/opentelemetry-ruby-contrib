# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
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
  c.use 'OpenTelemetry::Instrumentation::ActiveModelSerializers'
end

# no manual subscription trigger

at_exit do
  OpenTelemetry.tracer_provider.shutdown
end

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for Action Controller.
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  credentials.secret_key_base = 'secret_key_base'

  config.eager_load = false

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger
end

# Rails app initialization will pick up the instrumentation Railtie
# and subscribe to Active Support notifications
TraceRequestApp.initialize!

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
