# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampling::RateLimited::Sampler do
  describe '#should_sample?' do
    it 'returns DROP if credits_per_second is 0' do
      sampler = OpenTelemetry::Sampling::RateLimited::Sampler.new 0

      _(
        sampler.should_sample?(
          trace_id: SecureRandom.uuid.to_s,
          parent_context: nil,
          links: [],
          name: SecureRandom.uuid.to_s,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal false
    end

    it 'returns DROP if credits_per_second is negative' do
      sampler = OpenTelemetry::Sampling::RateLimited::Sampler.new -1

      _(
        sampler.should_sample?(
          trace_id: SecureRandom.uuid.to_s,
          parent_context: nil,
          links: [],
          name: SecureRandom.uuid.to_s,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal false
    end

    it 'adheres to the credits_per_second limit' do
      sampler = OpenTelemetry::Sampling::RateLimited::Sampler.new 3

      Process.stub :clock_gettime, Time.now do
        3.times do
          _(
            sampler.should_sample?(
              trace_id: SecureRandom.uuid.to_s,
              parent_context: nil,
              links: [],
              name: SecureRandom.uuid.to_s,
              kind: :internal,
              attributes: {}
            ).sampled?
          ).must_equal true
        end

        3.times do
          _(
            sampler.should_sample?(
              trace_id: SecureRandom.uuid.to_s,
              parent_context: nil,
              links: [],
              name: SecureRandom.uuid.to_s,
              kind: :internal,
              attributes: {}
            ).sampled?
          ).must_equal false
        end
      end

      Process.stub :clock_gettime, Time.now + 3 do
        3.times do
          _(
            sampler.should_sample?(
              trace_id: SecureRandom.uuid.to_s,
              parent_context: nil,
              links: [],
              name: SecureRandom.uuid.to_s,
              kind: :internal,
              attributes: {}
            ).sampled?
          ).must_equal true
        end
      end
    end
  end
end
