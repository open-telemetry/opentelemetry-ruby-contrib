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

    # Prevent tests from creating log/*.log
    level = ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym
    app.config.logger = ActiveSupport::Logger.new(LOG_STREAM, level: level)
    app.config.log_level = level
    app.config.filter_parameters = [:param_to_be_filtered]

    case Rails.version
    when /^6\.0/
      apply_rails_6_0_configs(app)
    when /^6\.1/
      apply_rails_6_1_configs(app)
    when /^7\./
      apply_rails_7_configs(app)
    end

    app.initialize!

    app
  end

  private

  def apply_rails_6_0_configs(application)
    # Required in Rails 6
    application.config.hosts << 'example.org'
    # Creates a lot of deprecation warnings on subsequent app initializations if not explicitly set.
    application.config.action_view.finalize_compiled_template_methods = ActionView::Railtie::NULL_OPTION
  end

  def apply_rails_6_1_configs(application)
    # Required in Rails 6
    application.config.hosts << 'example.org'
  end

  def apply_rails_7_configs(application)
    # Required in Rails 7
    application.config.hosts << 'example.org'

    # Unfreeze values which may have been frozen on previous initializations.
    ActiveSupport::Dependencies.autoload_paths =
      ActiveSupport::Dependencies.autoload_paths.dup
    ActiveSupport::Dependencies.autoload_once_paths =
      ActiveSupport::Dependencies.autoload_once_paths.dup
  end
end
