# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/poller')

describe(OpenTelemetry::Sampling::XRay::Poller) do
  describe('#start') do
    it('updates rules instantly') do
      cache = Minitest::Mock.new
      client = Minitest::Mock.new
      rules = [
        OpenTelemetry::Sampling::XRay::Client::SamplingRuleRecord.new(
          sampling_rule: build_rule,
          created_at: Time.now,
          modified_at: Time.now
        )
      ]

      client.expect(:fetch_sampling_rules, rules)
      cache.expect(:update_rules, nil, [rules.map(&:sampling_rule)])

      poller = OpenTelemetry::Sampling::XRay::Poller.new(
        client: client,
        cache: cache,
        rule_interval: 1,
        target_interval: 0
      )

      poller.start
      poller.stop

      client.verify
      cache.verify
    end

    it('updates rules periodically') do
      cache = Minitest::Mock.new
      client = Minitest::Mock.new

      first_rules = [
        OpenTelemetry::Sampling::XRay::Client::SamplingRuleRecord.new(
          sampling_rule: build_rule,
          created_at: Time.now,
          modified_at: Time.now
        )
      ]
      second_rules = [
        OpenTelemetry::Sampling::XRay::Client::SamplingRuleRecord.new(
          sampling_rule: build_rule,
          created_at: Time.now,
          modified_at: Time.now
        )
      ]

      client.expect(:fetch_sampling_rules, first_rules)
      cache.expect(:update_rules, nil, [first_rules.map(&:sampling_rule)])
      cache.expect(:get_matched_rules, [])
      client.expect(:fetch_sampling_rules, second_rules)
      cache.expect(:update_rules, nil, [second_rules.map(&:sampling_rule)])

      poller = OpenTelemetry::Sampling::XRay::Poller.new(
        client: client,
        cache: cache,
        rule_interval: 0.5,
        target_interval: 1
      )

      poller.start
      sleep(1.5)
      poller.stop

      client.verify
      cache.verify
    end

    it('updates targets periodically') do
      cache = Minitest::Mock.new
      client = Minitest::Mock.new
      rules = [
        OpenTelemetry::Sampling::XRay::Client::SamplingRuleRecord.new(
          sampling_rule: build_rule,
          created_at: Time.now,
          modified_at: Time.now
        )
      ]
      matched_rules = [build_rule]
      targets = OpenTelemetry::Sampling::XRay::Client::SamplingTargetResponse.new(
        last_rule_modification: Time.now,
        sampling_target_documents: [
          OpenTelemetry::Sampling::XRay::Client::SamplingTargetDocument.new(
            rule_name: SecureRandom.uuid.to_s,
            fixed_rate: rand,
            reservoir_quota: rand(0..100),
            reservoir_quota_ttl: rand(0..100),
            interval: rand(0..100)
          )
        ]
      )

      client.expect(:fetch_sampling_rules, rules)
      cache.expect(:update_rules, nil, [rules.map(&:sampling_rule)])
      cache.expect(:get_matched_rules, matched_rules)
      client.expect(:fetch_sampling_targets, targets, [matched_rules])
      cache.expect(:update_targets, nil, [targets.sampling_target_documents])

      poller = OpenTelemetry::Sampling::XRay::Poller.new(
        client: client,
        cache: cache,
        rule_interval: 10,
        target_interval: 1
      )

      poller.start
      sleep(1.5)
      poller.stop

      client.verify
      cache.verify
    end
  end
end
