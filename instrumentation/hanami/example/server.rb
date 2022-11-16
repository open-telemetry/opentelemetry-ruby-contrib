#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'hanami', '~> 2.0.0.rc1'
  gem 'hanami-router', '~> 2.0.0.rc1'
  gem 'hanami-controller', '~> 2.0.0.rc1'

  gem 'rack', '2.2.4'
  gem 'puma'

  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-hanami', path: '../../hanami'
end

# To run this example run the `rackup` command
# Example: rackup config.ru
# Navigate to http://localhost:9292/
# Spans for the requests will appear in the console

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Hanami'
end
