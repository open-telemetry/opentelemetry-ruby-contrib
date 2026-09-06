# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'logger'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'active_support'
require 'active_support/railtie'
require 'action_controller'
require 'action_controller/railtie'
require 'action_view'
require 'action_view/railtie'
require 'rails'
require 'opentelemetry-instrumentation-action_view'
require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::ActionView'
  c.add_span_processor span_processor
end

# Minimal Rails application for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(File::Constants::NULL)
  config.hosts << 'www.example.com'

  # Required for Rails initialization
  credentials.secret_key_base = 'test_secret_key_base'
end

TestApp.initialize!

# Set up views directory
ActionController::Base.prepend_view_path(File.expand_path('views', __dir__))

# Define test controllers
class PostsController < ActionController::Base
  layout 'application'

  def index
    @posts = ['Post 1', 'Post 2', 'Post 3']
    render template: 'posts/index'
  end

  def show
    @post = 'Single Post'
    render template: 'posts/show'
  end

  def api
    render template: 'posts/api', layout: false, formats: [:json]
  end

  def with_partial
    render template: 'posts/with_partial'
  end

  def with_collection
    @items = ['Item 1', 'Item 2', 'Item 3']
    render template: 'posts/with_collection'
  end

  def with_locals
    local_items = ['Item 1', 'Item 2', 'Item 3']
    render template: 'posts/with_locals', locals: { items: local_items }
  end
end

# Set up routes
TestApp.routes.draw do
  get '/posts', to: 'posts#index'
  get '/posts/show', to: 'posts#show'
  get '/posts/api', to: 'posts#api'
  get '/posts/with_partial', to: 'posts#with_partial'
  get '/posts/with_collection', to: 'posts#with_collection'
  get '/posts/with_locals', to: 'posts#with_locals'
end
