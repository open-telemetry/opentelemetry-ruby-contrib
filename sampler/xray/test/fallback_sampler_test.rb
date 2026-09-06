# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::FallbackSampler do
  before do
    # Freeze time at the current moment
    @current_time = Time.now
  end

  after do
    # Return to normal time
    Timecop.return
  end

  it 'test_should_sample' do
    Timecop.freeze(@current_time)
    sampler = OpenTelemetry::Sampler::XRay::FallbackSampler.new

    sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {}, links: [])

    # 0 seconds passed, 0 quota available
    sampled = 0
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # 0.4 seconds passed, 0.4 quota available
    sampled = 0
    @current_time += 0.4
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # Another 0.8 seconds passed, 1 quota available (1.2 quota capped at 1 quota), 1 quota consumed
    sampled = 0
    @current_time += 0.8
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # Another 1.9 seconds passed, 1 quota available (1.9 quota capped at 1 quota), 1 quota consumed
    sampled = 0
    @current_time += 1.9
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # Another 0.9 seconds passed, 0.9 quota available, 0 quota consumed
    sampled = 0
    @current_time += 0.9
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # Another 2.0 seconds passed, 1 quota available (2.0 quota capped at 1 quota), 1 quota consumed
    sampled = 0
    @current_time += 2.0
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # Another 2.4 seconds passed, 1 quota available (2.4 quota capped at 1 quota), 1 quota consumed
    sampled = 0
    @current_time += 2.4
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # Another 100 seconds passed, 1 quota available (100 quota capped at 1 quota), 1 quota consumed
    sampled = 0
    @current_time += 100
    Timecop.freeze(@current_time)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled
  end

  it 'test_to_string' do
    assert_equal(
      'FallbackSampler{fallback sampling with sampling config of 1 req/sec and 5% of additional requests}',
      OpenTelemetry::Sampler::XRay::FallbackSampler.new.description
    )
  end
end
