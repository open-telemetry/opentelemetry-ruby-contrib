# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Client
        # @param [String] endpoint
        def initialize(endpoint:)
          @endpoint = endpoint
        end

        # @return [Array<SamplingRule>]
        def fetch_sampling_rules
          raise(NotImplementedError)
        end

        # @return [Array<SamplingTargetDocument>]
        def fetch_sampling_targets
          raise(NotImplementedError)
        end

        class SamplingTargetDocument
          attr_reader(
            :rule_name,
            :fixed_rate,
            :reservoir_quota,
            :reservoir_quota_ttl,
            :interval
          )

          # @param [String] rule_name
          # @param [Float] fixed_rate
          # @param [Integer] reservoir_quota
          # @param [Integer] reservoir_quota_ttl
          # @param [Integer] interval
          def initialize(
            rule_name:,
            fixed_rate:,
            reservoir_quota:,
            reservoir_quota_ttl:,
            interval:
          )
            @rule_name = rule_name
            @fixed_rate = fixed_rate
            @reservoir_quota = reservoir_quota
            @reservoir_quota_ttl = reservoir_quota_ttl
            @interval = interval
          end
        end
      end
    end
  end
end
