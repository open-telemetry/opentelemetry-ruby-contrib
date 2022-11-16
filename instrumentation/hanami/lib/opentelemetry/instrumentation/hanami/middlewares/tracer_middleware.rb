# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'opentelemetry-instrumentation-rack'

module OpenTelemetry
  module Instrumentation
    module Hanami
      module Middlewares
        # Middleware to trace Sinatra requests
        class TracerMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            response = @app.call(env)
          ensure
            trace_response(env, response)
          end

          def trace_response(env, response)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            span.set_attribute('http.route', env['hanami.route'].split.last) if env['hanami.route']
            span.name = env['hanami.route'] if env['hanami.route']

            sinatra_response = ::Sinatra::Response.new([], response.first)
            return unless sinatra_response.server_error?

            span.record_exception(env['hanami.error'])
            span.status = OpenTelemetry::Trace::Status.error
          end
        end
      end
    end
  end
end
