# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../lib/opentelemetry/instrumentation/rage/log_context'

describe OpenTelemetry::Instrumentation::Rage::LogContext do
  subject { OpenTelemetry::Instrumentation::Rage::LogContext.call }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  describe 'with no active span' do
    it 'returns nil' do
      _(subject).must_be_nil
    end
  end

  describe 'with active span' do
    before { instrumentation.install({}) }
    after { instrumentation.instance_variable_set(:@installed, false) }

    it 'returns a hash with trace_id and span_id' do
      instrumentation.tracer.in_span('test span') do |span|
        _(subject[:trace_id]).must_equal(span.context.hex_trace_id)
        _(subject[:span_id]).must_equal(span.context.hex_span_id)
      end
    end
  end

  describe 'with an exception' do
    it 'handles raised exceptions' do
      OpenTelemetry::Trace.stub(:current_span, ->(**) { raise 'Test Error' }) do
        expect(OpenTelemetry).to receive(:handle_error).with(exception: instance_of(RuntimeError))
        _(subject).must_be_nil
      end
    end
  end
end
