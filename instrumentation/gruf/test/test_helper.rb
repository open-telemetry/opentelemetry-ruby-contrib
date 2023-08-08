# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'minitest/autorun'
require 'webmock/minitest'
require 'google/protobuf'
require 'gruf'

require_relative '../lib/opentelemetry/instrumentation/gruf'
require_relative '../lib/opentelemetry/instrumentation/gruf/interceptors/client'
require_relative '../lib/opentelemetry/instrumentation/gruf/interceptors/server'
require_relative '../example/proto/example_api_pb'
require_relative '../example/proto/example_api_services_pb'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
