# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 85

require 'opentelemetry/instrumentation'
require 'opentelemetry-test-helpers'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
