# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

class TestOpenTelemetry < Minitest::Test
  def setup
    @exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
  end

  def test_installs
    OpenTelemetry::SDK.configure do |c|
      # force a failure on error
      c.error_handler = ->(exception:, message:) { raise(exception || message) }
      c.logger = Logger.new(File::NULL, level: :fatal)
      c.add_span_processor OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(@exporter)
      c.use_all
    end

    tracer = OpenTelemetry.tracer_provider.tracer('releases', '1.0')
    tracer.in_span('test') {}

    spans = @exporter.finished_spans
    assert_equal(['test'], spans.map(&:name))
  end
end
