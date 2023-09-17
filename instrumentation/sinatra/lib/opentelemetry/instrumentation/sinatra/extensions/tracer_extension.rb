# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../middlewares/tracer_middleware'

module OpenTelemetry
  module Instrumentation
    module Sinatra
      module Extensions
        # Sinatra extension that installs TracerMiddleware and provides
        # tracing for template rendering
        module TracerExtension

          # Sinatra hook after extension is registered
          def self.registered(app)

            ::Sinatra::Base.module_eval do
              # Invoked when a matching route is found.
              # This method yields directly to user code.
              def route_eval
                Sinatra::Instrumentation.instance.tracer.in_span(
                  'sinatra.route_eval',
                  attributes: {
                    'sinatra.route' => request.path,
                    'sinatra.request_method' => request.request_method,
                    'sinatra.resource' => "#{request.request_method} #{request.path}",
                  }
                ) do
                  throw :halt, yield
                  # Can't use super?
                  # super
                end
              end

              # Create tracing `render` method
              def render(_engine, data, *)
                template_name = data.is_a?(Symbol) ? data : :literal

                Sinatra::Instrumentation.instance.tracer.in_span(
                  'sinatra.render_template',
                  attributes: { 'sinatra.template_name' => template_name.to_s }
                ) do
                  super
                end
              end
            end

            app.use(*OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args)
            app.use(Middlewares::TracerMiddleware)
          end
        end
      end
    end
  end
end
