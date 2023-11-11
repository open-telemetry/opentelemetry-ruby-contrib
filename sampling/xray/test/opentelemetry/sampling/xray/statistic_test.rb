# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/statistic')

describe(OpenTelemetry::Sampling::XRay::Statistic) do
  describe('#increment_borrow_count') do
    it('should increment the borrowed count') do
      statistic = OpenTelemetry::Sampling::XRay::Statistic.new
      increments = rand(0..100)
      increments.times.each { statistic.increment_borrow_count }
      _(statistic.instance_variable_get(:@borrow_count)).must_equal(increments)
    end
  end

  describe('#increment_request_count') do
    it('should increment the request count') do
      statistic = OpenTelemetry::Sampling::XRay::Statistic.new
      increments = rand(0..100)
      increments.times.each { statistic.increment_request_count }
      _(statistic.instance_variable_get(:@request_count)).must_equal(increments)
    end
  end

  describe('#increment_sampled_count') do
    it('should increment the sampled count') do
      statistic = OpenTelemetry::Sampling::XRay::Statistic.new
      increments = rand(0..100)
      increments.times.each { statistic.increment_sampled_count }
      _(statistic.instance_variable_get(:@sampled_count)).must_equal(increments)
    end
  end
end
