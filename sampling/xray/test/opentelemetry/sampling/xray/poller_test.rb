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
      rules = [SecureRandom.uuid.to_s]

      client.expect(:fetch_sampling_rules, rules)
      cache.expect(:update_rules, nil, [rules])

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

      first_rules = [SecureRandom.uuid.to_s]
      second_rules = [SecureRandom.uuid.to_s]

      client.expect(:fetch_sampling_rules, first_rules)
      cache.expect(:update_rules, nil, [first_rules])
      client.expect(:fetch_sampling_rules, second_rules)
      cache.expect(:update_rules, nil, [second_rules])

      poller = OpenTelemetry::Sampling::XRay::Poller.new(
        client: client,
        cache: cache,
        rule_interval: 1,
        target_interval: 0
      )

      poller.start
      sleep(2)
      poller.stop

      client.verify
      cache.verify
    end
  end
end
