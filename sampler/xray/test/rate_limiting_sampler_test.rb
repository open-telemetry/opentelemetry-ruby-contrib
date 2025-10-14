# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::RateLimitingSampler do
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
    sampler = OpenTelemetry::Sampler::XRay::RateLimitingSampler.new(30)

    sampled = 0
    100.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 0, sampled

    @current_time += 0.5
    Timecop.freeze(@current_time) # Move forward half a second

    sampled = 0
    100.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 15, sampled

    @current_time += 1
    Timecop.freeze(@current_time) # Move forward 1 second

    sampled = 0
    100.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 30, sampled

    @current_time += 2.5
    Timecop.freeze(@current_time) # Move forward 2.5 more seconds

    sampled = 0
    100.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 30, sampled

    @current_time += 1000
    Timecop.freeze(@current_time) # Move forward 1000 seconds

    sampled = 0
    100.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 30, sampled
  end

  it 'test_should_sample_with_quota_of_one' do
    sampler = OpenTelemetry::Sampler::XRay::RateLimitingSampler.new(1)

    sampled = 0
    50.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 0, sampled

    @current_time += 0.5
    Timecop.freeze(@current_time) # Move forward half a second

    sampled = 0
    50.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 0, sampled

    @current_time += 0.5
    Timecop.freeze(@current_time) # Move forward another half second

    sampled = 0
    50.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 1, sampled

    @current_time += 1000
    Timecop.freeze(@current_time) # Move forward 1000 seconds

    sampled = 0
    50.times do
      next unless sampler.should_sample?(parent_context: nil,
                                         trace_id: '3759e988bd862e3fe1be46a994272793',
                                         name: 'name',
                                         kind: OpenTelemetry::Trace::SpanKind::SERVER,
                                         attributes: {},
                                         links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

      sampled += 1
    end
    assert_equal 1, sampled
  end

  it 'test_to_string' do
    assert_equal(
      'RateLimitingSampler{rate limiting sampling with sampling config of 123 req/sec and 0% of additional requests}',
      OpenTelemetry::Sampler::XRay::RateLimitingSampler.new(123).to_s
    )
  end
end
