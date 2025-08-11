# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rails'
require 'action_controller/railtie'

require 'bundler'
Bundler.require

# MyApp
class MyApp < Rails::Application
  config.secret_key_base = 'your_secret_key_here'
  config.eager_load = false
  config.logger = Logger.new($stdout)
  config.api_only = true
  config.active_support.to_time_preserves_timezone = :zone

  routes.draw do
    get '/', to: 'application#index'
    get '/hello', to: 'application#hello'
    post '/data', to: 'application#create'
  end
end

# ApplicationController
class ApplicationController < ActionController::API
  def index
    render json: { message: 'Hello World!', time: Time.current }
  end

  def hello
    name = params[:name] || 'World'
    render json: { greeting: "Hello #{name}!" }
  end

  def create
    render json: {
      message: 'Data received',
      data: params.except(:controller, :action)
    }
  end
end

MyApp.initialize!
