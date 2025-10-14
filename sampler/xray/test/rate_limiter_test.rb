# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'timecop'

describe OpenTelemetry::Sampler::XRay::RateLimiter do
  before do
    # Freeze time at the current moment
    @current_time = Time.now
  end

  after do
    # Return to normal time
    Timecop.return
  end

  it 'test_take' do
    Timecop.freeze(@current_time)
    limiter = OpenTelemetry::Sampler::XRay::RateLimiter.new(30, 1)

    # First batch - no quota is available
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 0, spent

    # Second batch - should get half the available quota after 0.5 seconds
    @current_time += 0.5
    Timecop.freeze(@current_time)
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 15, spent

    # Third batch - should get all the available quota after 1 second
    @current_time += 1
    Timecop.freeze(@current_time)
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 30, spent
  end

  it 'test_take_with_zero_quota' do
    limiter = OpenTelemetry::Sampler::XRay::RateLimiter.new(0, 1)

    # Zero quota should always return false
    refute limiter.take(1)
  end

  it 'test_take_with_negative_quota' do
    limiter = OpenTelemetry::Sampler::XRay::RateLimiter.new(-5, 1)

    # Negative quota should always return false
    refute limiter.take(1)
  end
end
