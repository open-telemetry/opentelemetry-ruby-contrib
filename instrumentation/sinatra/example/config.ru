#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Example rack application that manually manages tracer middleware

require 'rubygems'
require 'bundler/setup'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use_all({
    'OpenTelemetry::Instrumentation::Rack' => { },
    'OpenTelemetry::Instrumentation::Sinatra' => { install_rack: false }
  })
end

# Example application for the Sinatra instrumentation
class App < Sinatra::Base
  set :show_exceptions, false

  template :example_render do
    'Example Render'
  end

  get '/example' do
    'Sinatra Instrumentation Example'
  end

  # Uses `render` method
  get '/example_render' do
    erb :example_render
  end

  get '/thing/:id' do
    'Thing 1'
  end

  get '/error' do
    raise 'Panic!'
  end
end

use(*OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args)
run App
