# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'extensions/tracer_extension'

module OpenTelemetry
  module Instrumentation
    module Sinatra
      # The Instrumentation class contains logic to detect and install the Sinatra
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install({}) if config[:install_rack]

          ::Sinatra::Base.register Extensions::TracerExtension
        end

        option :install_rack, default: true, validate: :boolean

        present do
          defined?(::Sinatra)
        end

        def install_middleware(app)
          app.use(*OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args) if config[:install_rack]
          app.use(Middlewares::TracerMiddleware)
        end
      end
    end
  end
end
