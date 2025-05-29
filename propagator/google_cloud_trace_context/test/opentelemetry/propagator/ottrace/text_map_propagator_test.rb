# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::GoogleCloudTraceContext::TextMapPropagator do
  class FakeGetter
    def get(carrier, key)
      '7ffe3d75a2b8ef468ab34365ee891f08/2141054039718851918;o=0'
    end

    def keys(carrier)
      []
    end
  end

  class FakeSetter
    def set(carrier, key, value)
      carrier[key] = "#{key} = #{value}"
    end
  end

  let(:span_id) do
    'e457b5a2e4d86bd1'
  end

  let(:trace_id) do
    '80f198ee56343ba864fe8b2a57d3eff7'
  end

  let(:trace_flags) do
    OpenTelemetry::Trace::TraceFlags::DEFAULT
  end

  let(:context) do
    OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace.non_recording_span(
        OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end

  let(:propagator) do
    OpenTelemetry::Propagator::GoogleCloudTraceContext::TextMapPropagator.new
  end

  let(:parent_context) do
    OpenTelemetry::Context.empty
  end

  let(:gcp_header) do
    "#{trace_id}/#{span_id.to_i(16)};o=1"
  end

  let(:carrier) do
    { 'x-cloud-trace-context' => gcp_header }
  end

  describe '#extract' do
    describe 'given an empty context' do
      let(:carrier) do
        {}
      end

      it 'skips context extraction' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('0' * 32)
        _(extracted_context.hex_span_id).must_equal('0' * 16)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).wont_be(:remote?)
      end
    end

    describe 'given a minimal context' do
      it 'extracts parent context' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).must_equal(span_id)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a minimal context with uppercase fields' do
      let(:carrier) do
        { 'x-cloud-trace-context' => gcp_header.upcase }
      end

      it 'extracts parent context' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).must_equal(span_id)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with sampling bit set to enabled' do
      it 'extracts sampled trace flag' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).must_equal(span_id)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with a sampling bit set to disabled' do
      let(:carrier) do
        { 'x-cloud-trace-context' => "#{trace_id}/#{span_id.to_i(16)};o=0" }
      end

      it 'extracts a default trace flag' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal(trace_id)
        _(extracted_context.hex_span_id).must_equal(span_id)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given context with a malformed trace id' do
      let(:carrier) do
        { 'x-cloud-trace-context' => "abc123/#{span_id.to_i(16)};o=1" }
      end

      it 'skips content extraction' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'given context with a malformed span id' do
      let(:carrier) do
        { 'x-cloud-trace-context' => "#{trace_id}/abc123;o=1" }
      end

      it 'skips content extraction' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'given an alternative getter parameter' do
      it 'will use the alternative getter instead of the constructor provided one' do
        context = propagator.extract(carrier, context: parent_context, getter: FakeGetter.new)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('7ffe3d75a2b8ef468ab34365ee891f08')
        _(extracted_context.hex_span_id).must_equal('1db68d4e2a5b754e')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end
  end

  describe '#inject' do
    describe 'when provided invalid trace ids' do
      let(:trace_id) do
        '0' * 32
      end

      it 'skips injecting context' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'when provided invalid span ids' do
      let(:span_id) do
        '0' * 16
      end

      it 'skips injecting context' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'given a minimal context' do
      it 'injects OpenTracing headers' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier.fetch('x-cloud-trace-context')).must_equal("#{trace_id}/#{span_id.to_i(16)};o=0")
      end
    end

    describe 'given a sampled trace flag' do
      let(:trace_flags) do
        OpenTelemetry::Trace::TraceFlags::SAMPLED
      end

      it 'injects OpenTracing headers' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier.fetch('x-cloud-trace-context')).must_equal("#{trace_id}/#{span_id.to_i(16)};o=1")
      end
    end

    describe 'given an alternative setter parameter' do
      it 'will use the alternative setter instead of the constructor provided one' do
        carrier = {}

        alternate_setter = FakeSetter.new
        propagator.inject(carrier, context: context, setter: alternate_setter)

        _(carrier.fetch('x-cloud-trace-context')).must_equal("x-cloud-trace-context = #{trace_id}/#{span_id.to_i(16)};o=0")
      end
    end
  end
end
