# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/cache')

describe(OpenTelemetry::Sampling::XRay::Cache) do
  describe('#get_first_matching_rule') do
    it('returns nil if no rule matches') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new
      resource = OpenTelemetry::SDK::Resources::Resource.create

      rule = Minitest::Mock.new
      rule.expect(:priority, rand)
      rule.expect(:rule_name, SecureRandom.uuid.to_s)
      rule.expect(:matches?, false, resource: resource, attributes: {})

      cache.update_rules([rule])

      _(
        cache.get_first_matching_rule(
          attributes: {},
          resource: resource
        )
      ).must_be_nil

      rule.verify
    end

    it('returns the first matching rule') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new
      resource = OpenTelemetry::SDK::Resources::Resource.create

      rule = Minitest::Mock.new
      rule.expect(:priority, rand)
      rule.expect(:rule_name, SecureRandom.uuid.to_s)
      rule.expect(:matches?, true, resource: resource, attributes: {})
      rule.expect(:==, true, [rule])

      cache.update_rules([rule])

      _(
        cache.get_first_matching_rule(
          attributes: {},
          resource: resource
        )
      ).must_equal(rule)

      rule.verify
    end
  end

  describe('#update_rules') do
    it('sorts rules by priority and name') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new
      rules = [
        build_rule(
          rule_name: 'b',
          priority: 1,
          fixed_rate: 0.5
        ),
        build_rule(
          rule_name: 'a',
          priority: 2,
          fixed_rate: 0.5
        ),
        build_rule(
          rule_name: 'a',
          priority: 1,
          fixed_rate: 0.5
        )
      ]

      cache.update_rules(rules)

      _(cache.instance_variable_get('@rules')).must_equal(
        [
          rules[2],
          rules[0],
          rules[1]
        ]
      )
    end
  end
end
