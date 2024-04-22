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
  let(:span) { Minitest::Mock.new }
  let(:context_with_baggage) { OpenTelemetry::Baggage.set_value('a_key', 'a_value') }

  describe '#on_start' do
    it 'adds current baggage keys/values as attributes when a span starts' do
      span.expect(:add_attributes, span, [{ 'a_key' => 'a_value' }])

      processor.on_start(span, context_with_baggage)

      span.verify
    end

    it 'does not blow up when given nil context' do
      processor.on_start(span, nil)
      assert true # nothing above raised an exception
    end
    it 'does not blow up when given nil span' do
      processor.on_start(nil, context_with_baggage)
      assert true # nothing above raised an exception
    end
    it 'does not blow up when given nil span and context' do
      processor.on_start(nil, nil)
      assert true # nothing above raised an exception
    end
    it 'does not blow up when given a context that is not a Context' do
      processor.on_start(span, :not_a_context)
      assert true # nothing above raised an exception
    end
    it 'does not blow up when given a span that is not a Span' do
      processor.on_start(:not_a_span, context_with_baggage)
      assert true # nothing above raised an exception
    end
  end

  describe 'satisfies the SpanProcessor duck type with no-op methods' do
    it 'implements #on_finish' do
      processor.on_finish(span)
      assert true # nothing above raised an exception
    end

    it 'implements #force_flush' do
      _(processor.force_flush).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    end

    it 'implements #shutdown' do
      _(processor.shutdown).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    end
  end

  describe 'integration test with an exporter' do
    let(:tracer) { OpenTelemetry.tracer_provider.tracer('🧳') }
    let(:exporter) { TEST_EXPORTER }

    before do
      exporter.reset
    end

    it 'adds baggage attributes to spans' do
      tracer
        .start_span('integration test span', with_parent: context_with_baggage)
        .finish

      _(exporter.finished_spans.size).must_equal(1)
      _(exporter.finished_spans.first.name).must_equal('integration test span')
      _(exporter.finished_spans.first.attributes).must_equal('a_key' => 'a_value')
    end
  end
end
