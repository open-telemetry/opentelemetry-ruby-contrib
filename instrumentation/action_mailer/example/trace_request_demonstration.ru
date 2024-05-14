# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'opentelemetry-sdk'
  gem 'stringio', '~> 3'
  gem 'opentelemetry-instrumentation-active_support', path: '../../active_support'
  gem 'opentelemetry-instrumentation-action_mailer', path: '../'
end

require 'action_mailer/railtie'

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  credentials.secret_key_base = 'secret_key_base'

  config.eager_load = false

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger
  
  config.action_mailer.delivery_method = :test
end

# A minimal test ApplicationMailer
class TestMailer < ActionMailer::Base
  default from: 'no-reply@example.com'

  def welcome_email
    mail(to: 'test_mailer@otel.org', subject: 'Welcome to OpenTelemetry!', cc: 'cc@example.com', bcc: 'bcc@example.com')
  end
end

# Simple setup for demonstration purposes, simple span processor should not be
# used in a production environment
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActionMailer'
  c.add_span_processor(span_processor)
end

Rails.application.initialize!

TestMailer.welcome_email.deliver_now

# To run this example run the `ruby` command with this file
# Example: ruby trace_request_demonstration.ru
# Spans for the requests will appear in the console
