# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay::TextMapPropagator do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags

  let(:propagator) { OpenTelemetry::Propagator::XRay::TextMapPropagator.new }

  describe('#extract') do
    it 'extracts context with trace id, span id, sampling flag' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1' }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1' }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with lineage in header' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1;Lineage=100:e3b0c442:11' }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context
      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(OpenTelemetry::Baggage.value('Lineage', context: context)).must_equal('100:e3b0c442:11')
    end

    it 'converts debug flag to sampled' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=d' }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
    end

    it 'handles malformed trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=180f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1' }

      context = propagator.extract(carrier, context: parent_context)

      _(context).must_equal(parent_context)
    end

    it 'handles malformed span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=457b5a2e4d86bd1;Sampled=1' }

      context = propagator.extract(carrier, context: parent_context)

      _(context).must_equal(parent_context)
    end
    it 'handles missing header gracefully' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {}

      context = propagator.extract(carrier, context: parent_context)

      _(context).must_equal(parent_context)
    end
    it 'handles invalid lineage' do
      invalid_lineages = [
        "",
        "::",
        "1::",
        "1::1",
        "1:badc0de:13",
        ":fbadc0de:13",
        "65535:fbadc0de:255",
      ]

      invalid_lineages.each do |lineage|
        parent_context = OpenTelemetry::Context.empty
        carrier = { 'X-Amzn-Trace-Id' => "Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1;Lineage=65535:fbadc0de:255" }

        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context
        _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(OpenTelemetry::Baggage.value('Lineage', context: context)).must_be_nil
      end
    end
  end

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      expected_xray = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::DEFAULT
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      expected_xray = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=0'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'injects debug flag when present' do
      context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        xray_debug: true
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      expected_xray = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=d'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'injects lineage from baggage' do
      context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::DEFAULT
      )
      context = OpenTelemetry::Baggage.set_value('Lineage', '100:e3b0c442:11', context: context)

      carrier = {}
      propagator.inject(carrier, context: context)

      expected_xray = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=0;Lineage=100:e3b0c442:11'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier.key?('X-Amzn-Trace-Id')).must_equal(false)
    end

    it 'no-ops if span id invalid' do
      context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: '0' * 16
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier.key?('X-Amzn-Trace-Id')).must_equal(false)
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: TraceFlags::DEFAULT,
                     xray_debug: false)
    context = OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace.non_recording_span(
        SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
    context = OpenTelemetry::Propagator::XRay.context_with_debug(context) if xray_debug
    context
  end
end
