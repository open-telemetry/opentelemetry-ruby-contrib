# frozen_string_literal: true

require 'bundler/setup'

Bundler.require

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-grape'
require 'grape'

# Export traces to console
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'trace_demonstration'
  c.use 'OpenTelemetry::Instrumentation::Grape'
end

# A basic Grape API example
class ExampleAPI < Grape::API
  format :json

  desc 'Return a greeting message'
  get :hello do
    { message: 'Hello, world!' }
  end

  desc 'Return information about a user'
  # Filters
  before { sleep(0.01) }
  after { sleep(0.01) }
  params do
    requires :id, type: Integer, desc: 'User ID'
  end
  get 'users/:id' do
    { id: params[:id], name: 'John Doe', email: 'johndoe@example.com' }
  end
end

# Set up fake Rack application
builder = Rack::Builder.app { run ExampleAPI }
app = Rack::MockRequest.new(builder)

app.get('/hello')
app.get('/users/1')
