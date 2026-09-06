# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# Monkey-patch webmock to support HTTP.rb's 6.0+ keyword arguments
if defined?(HTTP::Response) && defined?(WebMock::HttpLibAdapters::HttpRbAdapter)
  module HTTP
    class Response
      class << self
        alias original_from_webmock from_webmock if method_defined?(:from_webmock)

        def from_webmock(request, webmock_response, request_signature = nil)
          # Mostly a copy, but remove a few conditions/variables related to versions we don't test
          status  = Status.new(webmock_response.status.first)
          headers = webmock_response.headers || {}
          body = build_http_rb_response_body_from_webmock_response(webmock_response)

          # This is the main change: remove the hash around the args on the
          # final "new" call
          new(
            status: status,
            version: '1.1',
            headers: headers,
            body: body,
            request: request
          )
        end
      end
    end
  end
end

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end
