# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'opentelemetry-propagator-vitess'
require 'minitest/autorun'

if ENV['ENABLE_COVERAGE'].to_i.positive?
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end

OpenTelemetry.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
