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
    Timecop.freeze(@current_time)
  end

  after do
    # Return to normal time
    Timecop.return
  end

  it 'test_take' do
    limiter = OpenTelemetry::Sampler::XRay::RateLimiter.new(30, 1)

    # First batch - should get no tokens immediately
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 0, spent

    # Second batch - should get half the rate after 0.5 seconds
    Timecop.travel(@current_time + 0.5)
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 15, spent

    # Third batch - should get full rate after 1 second
    Timecop.travel(@current_time + 1000)
    spent = 0
    100.times do
      spent += 1 if limiter.take(1)
    end
    assert_equal 30, spent
  end
end
