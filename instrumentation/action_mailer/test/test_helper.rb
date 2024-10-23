# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'action_mailer'
require 'opentelemetry-instrumentation-action_mailer'
require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::ActionMailer'
  c.add_span_processor span_processor
end

OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})
OpenTelemetry::Instrumentation::ActionMailer::Instrumentation.instance.install({})

ActionMailer::Base.delivery_method = :test

class TestMailer < ActionMailer::Base
  FROM = 'from@example.com'
  TO = 'to@example.com'
  CC = 'cc@example.com'
  BCC = 'bcc@example.com'

  def hello_world(message = 'Hello world')
    @message = message
    mail from: FROM, to: TO, cc: CC, bcc: BCC do |format|
      format.html { render inline: '<h1><%= @message %></h1>' }
      format.text { render inline: '<%= @message %>' }
    end
  end
end
