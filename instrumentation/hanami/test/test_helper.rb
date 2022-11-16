# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'hanami'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'

require 'minitest/autorun'
require 'rack/test'
require 'test_helpers/app_config'

require_relative '../lib/opentelemetry-instrumentation-hanami'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.logger = ::Logger.new(File::NULL)
  c.use_all
  c.add_span_processor span_processor
end

Hanami.prepare

# Create a globally available Hanami app, this should be used in test unless
# specifically testing behaviour with different initialization configs.
DEFAULT_HANAMI_APP = ::Hanami.app
