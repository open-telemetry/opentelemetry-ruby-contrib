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

  # Share OpenTelemetry objects across the app through Rails config.
  config.x.otel_meter = OpenTelemetry.meter_provider.meter('rails-example')
  config.x.otel_request_counter = config.x.otel_meter.create_counter(
    'http.request.count',
    description: 'Counts the number of HTTP requests'
  )
  config.x.otel_logger = OpenTelemetry.logger_provider.logger(name: 'rails-example')
end

# ApplicationController
# rubocop disable:Style/OneClassPerFile
class ApplicationController < ActionController::API
  def index
    MyApp.config.x.otel_request_counter.add(1, attributes: { 'http.route' => '/' })
    MyApp.config.x.otel_logger.on_emit(severity_text: 'INFO', body: 'Handling request: GET /')
    render json: { message: 'Hello World!', time: Time.current }
  end

  def hello
    MyApp.config.x.otel_request_counter.add(1, attributes: { 'http.route' => '/hello' })
    name = params[:name] || 'World'
    MyApp.config.x.otel_logger.on_emit(severity_text: 'INFO', body: "Handling request: GET /hello, name=#{name}")
    render json: { greeting: "Hello #{name}!" }
  end

  def create
    MyApp.config.x.otel_request_counter.add(1, attributes: { 'http.route' => '/data' })
    MyApp.config.x.otel_logger.on_emit(severity_text: 'INFO', body: 'Handling request: POST /data')
    render json: {
      message: 'Data received',
      data: params.except(:controller, :action)
    }
  end
end
# rubocop enable:Style/OneClassPerFile

MyApp.initialize!

MyApp.routes.draw do
  get '/', to: 'application#index'
  get '/hello', to: 'application#hello'
  post '/data', to: 'application#create'
end
