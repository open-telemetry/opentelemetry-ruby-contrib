# frozen_string_literal: true

require 'bundler/setup'

Bundler.require

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-grape'
require 'grape'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Grape'
end

# A basic Grape endpoint example
require 'grape'

class ExampleAPI < Grape::API
  format :json

  desc 'Return a greeting message'
  get :hello do
    { message: 'Hello, world!' }
  end

  desc 'Return information about a user'
  # Filters
  before do
    sleep(0.01)
  end
  after do
    sleep(0.01)
  end
  params do
    requires :id, type: Integer, desc: 'User ID'
  end
  get 'users/:id' do
    { id: params[:id], name: 'John Doe', email: 'johndoe@example.com' }
  end
end

# Set up fake Rack application
builder = Rack::Builder.app do
  run ExampleAPI
end

Rack::MockRequest.new(builder).get('/hello')
Rack::MockRequest.new(builder).get('/users/1')
