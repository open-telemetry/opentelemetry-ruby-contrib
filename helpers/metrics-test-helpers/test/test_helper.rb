# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-sdk'

begin
  require 'opentelemetry-metrics-sdk'
rescue LoadError # rubocop: disable Lint/SuppressedException
end

begin
  require 'opentelemetry-metrics-api'
rescue LoadError # rubocop: disable Lint/SuppressedException
end

OpenTelemetry::SDK.configure

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'opentelemetry-metrics-test-helpers'

require 'minitest/autorun'
