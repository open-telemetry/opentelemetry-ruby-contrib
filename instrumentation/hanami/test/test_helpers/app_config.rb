# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'config/app'
require_relative 'config/routes'
require_relative 'config/settings'

module AppConfig
  extend self

  def initialize_app # (use_exceptions_app: false, remove_rack_tracer_middleware: false)
    new_app = Bookshelf::Application.new

    # remove_rack_middleware(new_app) if remove_rack_tracer_middleware
    # add_exceptions_app(new_app) if use_exceptions_app
    # add_middlewares(new_app)

    new_app.setup

    Rack::Builder.new do
      run new_app
    end.to_app

    new_app
  end

  # private
  #
  # def remove_rack_middleware(application)
  #   application.middleware.delete(
  #     OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
  #   )
  # end
  #
  # def add_exceptions_app(application)
  #   application.config.exceptions_app = lambda do |env|
  #     ExceptionsController.action(:show).call(env)
  #   end
  # end
  #
  # def add_middlewares(application)
  #   application.middleware.insert_after(
  #     ActionDispatch::DebugExceptions,
  #     ExceptionRaisingMiddleware
  #   )
  #
  #   application.middleware.insert_after(
  #     ActionDispatch::DebugExceptions,
  #     RedirectMiddleware
  #   )
  # end
end
