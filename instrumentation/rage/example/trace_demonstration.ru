# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rage-rb'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rage'
end

require 'rage/all'

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rage'
end

class BaseController < RageController::API
  def index
    render plain: "Hello from OpenTelemetry!"
  end
end

Rage.routes.draw do
  root to: "base#index"
end

run Rage.application

# To run this example:
# 1. Install the `rage-rb` gem:
#   gem install rage-rb
# 2. Start the server:
#   rage s -c trace_demonstration.ru
# 3. Navigate to http://localhost:3000/
# Spans for the requests will appear in the console
