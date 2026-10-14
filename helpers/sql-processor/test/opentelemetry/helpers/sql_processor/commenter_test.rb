# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Helpers::SqlProcessor::SqlCommenter do
  let(:span_id) { 'e457b5a2e4d86bd1' }
  let(:trace_id) { '80f198ee56343ba864fe8b2a57d3eff7' }
  let(:trace_flags) { OpenTelemetry::Trace::TraceFlags::SAMPLED }

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

  describe 'SqlQueryPropagator.inject' do
    let(:propagator) { OpenTelemetry::Helpers::SqlProcessor::SqlCommenter.sql_query_propagator }

    it 'injects trace context into SQL' do
      sql = +'SELECT * FROM users'
      propagator.inject(sql, context: context)

      expected = "SELECT * FROM users /*traceparent='00-#{trace_id}-#{span_id}-01'*/"
      _(sql).must_equal(expected)
    end

    it 'handles frozen strings by not modifying them' do
      sql = -'SELECT * FROM users'
      propagator.inject(sql, context: context)

      # Frozen string should remain unchanged (setter will return early)
      _(sql).must_equal('SELECT * FROM users')
    end

    it 'handles empty context' do
      sql = +'SELECT * FROM users'
      propagator.inject(sql, context: OpenTelemetry::Context.empty)

      # Should not modify SQL when context produces no headers
      _(sql).must_equal('SELECT * FROM users')
    end

    it 'includes tracestate when present' do
      span_context = OpenTelemetry::Trace::SpanContext.new(
        trace_id: Array(trace_id).pack('H*'),
        span_id: Array(span_id).pack('H*'),
        trace_flags: trace_flags,
        tracestate: OpenTelemetry::Trace::Tracestate.from_string('congo=t61rcWkgMzE,rojo=00f067aa0ba902b7')
      )

      ctx = OpenTelemetry::Trace.context_with_span(
        OpenTelemetry::Trace.non_recording_span(span_context)
      )

      sql = +'SELECT * FROM users'
      propagator.inject(sql, context: ctx)

      expected = "SELECT * FROM users /*traceparent='00-#{trace_id}-#{span_id}-01',tracestate='congo%3Dt61rcWkgMzE%2Crojo%3D00f067aa0ba902b7'*/"
      _(sql).must_equal(expected)
    end

    it 'returns nil' do
      sql = +'SELECT * FROM users'
      result = propagator.inject(sql, context: context)

      _(result).must_be_nil
    end

    describe 'with a custom global propagator' do
      before do
        @original_propagation = OpenTelemetry.propagation
        OpenTelemetry.propagation = Class.new do
          def inject(carrier, context:)
            carrier['uberctx-*/;SELECT 2;--'] = 'value'
          end
        end.new
      end

      after do
        OpenTelemetry.propagation = @original_propagation
      end

      it 'keeps propagation keys inside the SQL comment' do
        sql = +'SELECT * FROM users'
        propagator.inject(sql, context: context)

        _(sql).must_equal("SELECT * FROM users /*uberctx-%2A%2F%3BSELECT%202%3B--='value'*/")
      end
    end
  end

  describe 'SqlQuerySetter.set' do
    let(:setter) { OpenTelemetry::Helpers::SqlProcessor::SqlCommenter::SqlQuerySetter }

    it 'formats headers as SQL comments' do
      sql = +'SELECT * FROM users'
      headers = { 'traceparent' => '00-80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-01' }

      setter.set(sql, headers)

      expected = "SELECT * FROM users /*traceparent='00-80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-01'*/"
      _(sql).must_equal(expected)
    end

    it 'URL encodes values' do
      sql = +'SELECT * FROM users'
      headers = { 'key' => 'value with spaces' }

      setter.set(sql, headers)

      expected = "SELECT * FROM users /*key='value%20with%20spaces'*/"
      _(sql).must_equal(expected)
    end

    it 'URL encodes keys' do
      sql = +'SELECT * FROM users'
      headers = { "key' ,=\\%" => 'value' }

      setter.set(sql, headers)

      _(sql).must_equal("SELECT * FROM users /*key%27%20%2C%3D%5C%25='value'*/")
    end

    it 'encodes SQL comment delimiters in keys and values' do
      sql = +'SELECT * FROM users'
      headers = { '*/ SELECT 2 /*' => "'*/ SELECT 3 /*" }

      setter.set(sql, headers)

      _(sql).must_equal("SELECT * FROM users /*%2A%2F%20SELECT%202%20%2F%2A='%27%2A%2F%20SELECT%203%20%2F%2A'*/")
    end

    it 'converts non-string keys and values to strings' do
      sql = +'SELECT * FROM users'
      headers = { custom: 123 }

      setter.set(sql, headers)

      _(sql).must_equal("SELECT * FROM users /*custom='123'*/")
    end

    it 'handles empty headers' do
      sql = +'SELECT * FROM users'
      setter.set(sql, {})

      _(sql).must_equal('SELECT * FROM users')
    end

    it 'handles frozen strings by not modifying them' do
      sql = -'SELECT * FROM users'
      headers = { 'traceparent' => '00-80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-01' }

      setter.set(sql, headers)

      # Frozen string should remain unchanged
      _(sql).must_equal('SELECT * FROM users')
    end
  end
end
