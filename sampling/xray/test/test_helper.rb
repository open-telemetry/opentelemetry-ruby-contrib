# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('bundler/setup')
Bundler.require(:default, :development, :test)

require('opentelemetry-sampling-xray')
require('minitest/autorun')

OpenTelemetry.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'info').to_sym)
