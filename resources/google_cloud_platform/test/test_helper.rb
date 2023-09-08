# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

SimpleCov.minimum_coverage 85
SimpleCov.start

require 'opentelemetry-resource-detector-google_cloud_platform'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
