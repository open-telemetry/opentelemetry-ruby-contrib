# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'grape', '~> 1.2'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rack'
  gem 'opentelemetry-instrumentation-grape'
end

# Export traces to console
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'trace_demonstration'
  c.use_all # this will only require instrumentation gems it finds that are installed by bundler.
end

at_exit do
  OpenTelemetry.tracer_provider.shutdown
end

# A basic Grape API example
class ExampleAPI < Grape::API
  format :json

  desc 'Return a greeting message'
  get :hello do
    { message: 'Hello, world!' }
  end

  desc 'Return information about a user'
  params do
    requires :id, type: Integer, desc: 'User ID'
  end
  get 'users/:id' do
    { id: params[:id], name: 'John Doe', email: 'johndoe@example.com' }
  end
end

# Set up fake Rack application
builder = Rack::Builder.app do
  # Integration is automatic in web frameworks but plain Rack applications require this line.
  # Enable it in your config.ru.
  use *OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args
  run ExampleAPI
end
app = Rack::MockRequest.new(builder)

app.get('/hello')
app.get('/users/1')
