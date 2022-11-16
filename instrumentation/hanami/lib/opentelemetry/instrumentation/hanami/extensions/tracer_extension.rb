# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../middlewares/tracer_middleware'

module OpenTelemetry
  module Instrumentation
    module Hanami
      module Extensions
        # Hanami extension that installs TracerMiddleware and provides
        # tracing for template rendering
        module TracerExtension
          # Hanami hook after extension is registered
          def self.registered(app)
            # Create tracing `render` method
            # ::Hanami::Web.module_eval do
            #   def render(_engine, data, *)
            #     template_name = data.is_a?(Symbol) ? data : :literal
            #
            #     Hanami::Instrumentation.instance.tracer.in_span(
            #       'hanami.render_template',
            #       attributes: { 'hanami.template_name' => template_name.to_s }
            #     ) do
            #       super
            #     end
            #   end
            # end
            app.use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
            app.use Middlewares::TracerMiddleware
          end
        end
      end
    end
  end
end
