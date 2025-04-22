# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::FallbackSampler do
  before do
    # Freeze time at the current moment
    @current_time = Time.now
    Timecop.freeze(@current_time)
  end

  after do
    # Return to normal time
    Timecop.return
  end

  it 'test_should_sample' do
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
    Timecop.freeze(@current_time + 0.4)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # 0.8 seconds passed, 0.8 quota available
    sampled = 0
    Timecop.freeze(@current_time + 0.8)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # 1.2 seconds passed, 1 quota consumed, 0 quota available
    sampled = 0
    Timecop.freeze(@current_time + 1.2)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # 1.6 seconds passed, 0.4 quota available
    sampled = 0
    Timecop.freeze(@current_time + 1.6)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # 2.0 seconds passed, 0.8 quota available
    sampled = 0
    Timecop.freeze(@current_time + 2.0)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 0, sampled

    # 2.4 seconds passed, one more quota consumed, 0 quota available
    sampled = 0
    Timecop.freeze(@current_time + 2.4)
    30.times do
      if sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: {},
                                links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
        sampled += 1
      end
    end
    assert_equal 1, sampled

    # 100 seconds passed, only one quota can be consumed
    sampled = 0
    Timecop.freeze(@current_time + 100)
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
