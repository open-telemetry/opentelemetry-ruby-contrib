# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class Application < Rails::Application; end
require 'action_controller/railtie'

module AppConfig
  extend self

  def initialize_app(use_exceptions_app: false, remove_rack_tracer_middleware: false)
    app = Application.new
    app.config.secret_key_base = 'secret_key_base'

    # Ensure we don't see this Rails warning when testing
    app.config.eager_load = false
    app.config.enable_reloading = false

    # Prevent tests from creating log/*.log
    level = ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym
    app.config.logger = ActiveSupport::Logger.new(LOG_STREAM, level: level)
    app.config.log_level = level
    app.config.filter_parameters = [:param_to_be_filtered]
    app.config.load_defaults([Rails::VERSION::MAJOR, Rails::VERSION::MINOR].compact.join('.'))

    app.initialize!

    app
  end
end
