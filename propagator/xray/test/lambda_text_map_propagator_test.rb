# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags

  let(:propagator) { OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator.new }

  describe('#extract') do
    it 'returns the original context when no headers or env vars exist' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {}

      # Ensure environment variable is not set
      original_env = ENV.fetch(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY, nil)
      ENV.delete(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY)

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.valid?).must_equal(false)
      _(context).must_equal(parent_context)

      # Restore original env value if it existed
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = original_env if original_env
    end

    it 'returns existing context when valid and no env var exists' do
      # Create a valid context
      valid_context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      carrier = {}

      # Ensure environment variable is not set
      original_env = ENV.fetch(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY, nil)
      ENV.delete(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY)

      context = propagator.extract(carrier, context: valid_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
      _(context).must_equal(valid_context)

      # Restore original env value if it existed
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = original_env if original_env
    end

    it 'extracts context from environment variable when no headers exist' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {}

      # Set environment variable with trace information
      original_env = ENV.fetch(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY, nil)
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1'

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)

      # Restore original env value if it existed
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = original_env if original_env
    end

    it 'prioritizes header over environment variable' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-90f198ea-f56343ba964fe8b2a67d3eff;Parent=f457b5a2e4d86bd2;Sampled=1' }

      # Set environment variable with different trace information
      original_env = ENV.fetch(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY, nil)
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = 'Root=1-80f198ea-e56343ba864fe8b2a57d3eff;Parent=e457b5a2e4d86bd1;Sampled=1'

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      # Should use the header, not the environment variable
      _(extracted_context.hex_trace_id).must_equal('90f198eaf56343ba964fe8b2a67d3eff')
      _(extracted_context.hex_span_id).must_equal('f457b5a2e4d86bd2')
      _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)

      # Restore original env value if it existed
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = original_env if original_env
    end

    it 'handles malformed environment variable gracefully' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {}

      # Set environment variable with malformed trace information
      original_env = ENV.fetch(OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY, nil)
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = 'NotAValidTraceHeader'

      context = propagator.extract(carrier, context: parent_context)

      # Should return the original context since the env var is invalid
      _(context).must_equal(parent_context)

      # Restore original env value if it existed
      ENV[OpenTelemetry::Propagator::XRay::LambdaTextMapPropagator::AWS_TRACE_HEADER_ENV_KEY] = original_env if original_env
    end

    it 'uses existing context when valid, even if headers exist' do
      # Create a valid context
      valid_context = create_context(
        trace_id: '80f198eae56343ba864fe8b2a57d3eff',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      # Create a carrier with header
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-90f198ea-f56343ba964fe8b2a67d3eff;Parent=f457b5a2e4d86bd2;Sampled=1' }

      context = propagator.extract(carrier, context: valid_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      # Should use the existing context, not the header
      _(extracted_context.hex_trace_id).must_equal('80f198eae56343ba864fe8b2a57d3eff')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
      _(context).must_equal(valid_context)
    end
  end

  # Helper method to create a context with specified values
  def create_context(trace_id:, span_id:, trace_flags: TraceFlags::DEFAULT, xray_debug: false)
    span_context = SpanContext.new(
      trace_id: Array(trace_id).pack('H*'),
      span_id: Array(span_id).pack('H*'),
      trace_flags: trace_flags,
      remote: false
    )

    span = Span.new(
      span_context: span_context
    )

    context = OpenTelemetry::Trace.context_with_span(span)
    return context unless xray_debug

    OpenTelemetry::Propagator::XRay.send(:context_with_debug, context)
  end
end
