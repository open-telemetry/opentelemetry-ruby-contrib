# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/reservoir')

describe(OpenTelemetry::Sampling::XRay::Reservoir) do
  describe('#borrow_or_take?') do
    it('should take if the quota is applicable and not yet fully consumed') do
      reservoir = OpenTelemetry::Sampling::XRay::Reservoir.new(0)
      reservoir.update_target(quota: 10, quota_ttl: Time.now.to_i + 100)

      Time.stub(:now, Time.now) do
        10.times.each do |i|
          _(reservoir.borrow_or_take?).must_equal(OpenTelemetry::Sampling::XRay::Reservoir::TAKE)
          _(reservoir.instance_variable_get(:@taken)).must_equal(i + 1)
        end

        _(reservoir.borrow_or_take?).must_equal(false)
        _(reservoir.instance_variable_get(:@taken)).must_equal(10)
      end
    end

    it('should borrow if it cannot take and has not borrowed yet') do
      reservoir = OpenTelemetry::Sampling::XRay::Reservoir.new(rand(1..100))

      Time.stub(:now, Time.now) do
        _(reservoir.borrow_or_take?).must_equal(OpenTelemetry::Sampling::XRay::Reservoir::BORROW)
        _(reservoir.instance_variable_get(:@borrowed)).must_equal(1)

        _(reservoir.borrow_or_take?).must_equal(false)
        _(reservoir.instance_variable_get(:@borrowed)).must_equal(1)
      end
    end

    it('should neither borrow nor take') do
      reservoir = OpenTelemetry::Sampling::XRay::Reservoir.new(0)

      Time.stub(:now, Time.now) do
        _(reservoir.borrow_or_take?).must_equal(false)
        _(reservoir.instance_variable_get(:@borrowed)).must_equal(0)
        _(reservoir.instance_variable_get(:@taken)).must_equal(0)
      end
    end

    it('should clear its state when the time advances') do
      reservoir = OpenTelemetry::Sampling::XRay::Reservoir.new(0)
      reservoir.update_target(quota: 1, quota_ttl: Time.now.to_i + 100)

      now = Time.now

      Time.stub(:now, now) do
        _(reservoir.borrow_or_take?).must_equal(OpenTelemetry::Sampling::XRay::Reservoir::TAKE)
        _(reservoir.borrow_or_take?).must_equal(false)
      end

      Time.stub(:now, now + 1) do
        _(reservoir.borrow_or_take?).must_equal(OpenTelemetry::Sampling::XRay::Reservoir::TAKE)
        _(reservoir.borrow_or_take?).must_equal(false)
      end
    end
  end
end
