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
      rule.expect(:match?, false, resource: resource, attributes: {})

      cache.instance_variable_set(:@rules, [rule])

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
      rule.expect(:match?, true, resource: resource, attributes: {})
      rule.expect(:==, true, [rule])

      cache.instance_variable_set(:@rules, [rule])

      _(
        cache.get_first_matching_rule(
          attributes: {},
          resource: resource
        )
      ).must_equal(rule)

      rule.verify
    end
  end

  describe('#get_matched_rules') do
    it('returns rules that matched at least once') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new

      matched_rule = Minitest::Mock.new
      matched_rule.expect(:ever_matched?, true)
      matched_rule.expect(:==, true, [matched_rule])

      not_matched_rule = Minitest::Mock.new
      not_matched_rule.expect(:ever_matched?, false)

      cache.instance_variable_set(:@rules, [matched_rule, not_matched_rule].shuffle)

      matched_rules = cache.get_matched_rules
      _(matched_rules.length).must_equal(1)
      _(matched_rules.first).must_equal(matched_rule)

      matched_rule.verify
      not_matched_rule.verify
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

    it('merges rules with their predecessor') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new

      rule = build_rule
      reservoir = OpenTelemetry::Sampling::XRay::Reservoir.new(rand(0..100))
      rule.instance_variable_set(:@reservoir, reservoir)
      statistic = OpenTelemetry::Sampling::XRay::Statistic.new
      rule.instance_variable_set(:@statistic, statistic)

      cache.update_rules([rule])

      new_rule = build_rule(rule_name: rule.rule_name)
      cache.update_rules([new_rule])

      _(cache.instance_variable_get(:@rules).length).must_equal(1)
      _(cache.instance_variable_get(:@rules).first).must_equal(new_rule)
      _(new_rule.reservoir).must_equal(reservoir)
      _(new_rule.statistic).must_equal(statistic)
    end
  end

  describe('#update_targets') do
    it('updates rule targets') do
      cache = OpenTelemetry::Sampling::XRay::Cache.new
      target = build_target_document

      rule = Minitest::Mock.new
      rule.expect(:with_target, nil, [target])
      rule.expect(:rule_name, target.rule_name)

      cache.instance_variable_set(:@rules, [rule])
      cache.update_targets([target])

      rule.verify
    end
  end
end
