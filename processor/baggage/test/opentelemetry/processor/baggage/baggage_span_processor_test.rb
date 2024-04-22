# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry/sdk'

TEST_EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new

OpenTelemetry::SDK.configure do |c|
  # the baggage processor getting wired in for testing
  c.add_span_processor OpenTelemetry::Processor::Baggage::BaggageSpanProcessor.new

  # use a simple processor and in-memory export for testing sent spans
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(TEST_EXPORTER)
  )

  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
end

describe OpenTelemetry::Processor::Baggage::BaggageSpanProcessor do
  let(:processor) { OpenTelemetry::Processor::Baggage::BaggageSpanProcessor.new }
  let(:exporter) { TEST_EXPORTER }

  before do
    exporter.reset
  end

  describe '#on_start' do
    it 'sets baggage on the span' do
      span = OpenTelemetry::Trace::Span.new
      span.context = OpenTelemetry::Trace::SpanContext.new
      span.context = span.context.create_with_baggage_item('key', 'value')

      processor.on_start(span)

      _(span.context.baggage).must_equal('key' => 'value')
    end
  end

  describe '#on_end' do
    it 'does not modify the span' do
      span = OpenTelemetry::Trace::Span.new
      span.context = OpenTelemetry::Trace::SpanContext.new
      span.context = span.context.create_with_baggage_item('key', 'value')

      processor.on_end(span)

      _(span.context.baggage).must_equal('key' => 'value')
    end
  end

  describe '#shutdown' do
    it 'does not modify the span' do
      processor.shutdown
    end
  end
end
