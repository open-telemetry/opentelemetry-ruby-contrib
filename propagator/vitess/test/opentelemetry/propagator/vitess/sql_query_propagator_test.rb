# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::Vitess::SqlQueryPropagator do
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
    OpenTelemetry::Propagator::Vitess::SqlQueryPropagator.new
  end

  let(:parent_context) do
    OpenTelemetry::Context.empty
  end

  let(:base64_encoded_jaeger_context) do
    Base64.strict_encode64({ 'uber-trace-id' => "#{trace_id}:#{span_id}:0:#{trace_flags.sampled? ? 1 : 0}" }.to_json)
  end

  let(:carrier) do
    +'SELECT * FROM users'
  end

  describe '#extract' do
    it 'returns the context' do
      context = propagator.extract(carrier, context: parent_context)
      _(context).must_equal(parent_context)
    end
  end

  describe '#inject' do
    describe 'when provided invalid trace ids' do
      let(:trace_id) do
        '0' * 32
      end

      it 'skips injecting context' do
        carrier = +''
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'when provided invalid span ids' do
      let(:span_id) do
        '0' * 16
      end

      it 'skips injecting context' do
        carrier = +''
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'given a minimal context' do
      it 'injects a SQL comment' do
        carrier = +'SELECT * FROM users'
        propagator.inject(carrier, context: context)

        _(carrier).must_equal("/*VT_SPAN_CONTEXT=#{base64_encoded_jaeger_context}*/SELECT * FROM users")
      end
    end

    describe 'when the carrier is frozen' do
      it 'does not raise an error' do
        carrier = -''
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'given a sampled trace flag' do
      let(:trace_flags) do
        OpenTelemetry::Trace::TraceFlags::SAMPLED
      end

      it 'injects a SQL comment' do
        carrier = +'SELECT * FROM users'
        propagator.inject(carrier, context: context)

        _(carrier).must_equal("/*VT_SPAN_CONTEXT=#{base64_encoded_jaeger_context}*/SELECT * FROM users")
      end
    end

    describe 'given an alternative setter parameter' do
      it 'will use the alternative setter instead of the constructor provided one' do
        carrier = {}

        propagator.inject(carrier, context: context, setter: OpenTelemetry::Context::Propagation::TextMapSetter.new)

        _(carrier.fetch('VT_SPAN_CONTEXT')).must_equal(base64_encoded_jaeger_context)
      end
    end
  end
end
