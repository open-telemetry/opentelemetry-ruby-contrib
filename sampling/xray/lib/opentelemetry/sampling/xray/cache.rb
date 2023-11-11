# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative('sampling_rule')

module OpenTelemetry
  module Sampling
    module XRay
      class Cache
        def initialize
          @rules = []
          @lock = Mutex.new
        end

        # @param [Hash<String, Object>] attributes
        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @return [SamplingRule]
        def get_first_matching_rule(attributes:, resource:)
          @lock.synchronize do
            @rules.find { |rule| rule.match?(resource: resource, attributes: attributes) }
          end
        end

        # @return [Array<SamplingRule>]
        def get_matched_rules
          @rules.select(&:ever_matched?)
        end

        # @param [Array<SamplingRule>] rules
        def update_rules(rules)
          sorted_rules = rules.sort_by { |rule| [rule.priority, rule.rule_name] }

          @lock.synchronize do
            current_rules = @rules.to_h { |rule| [rule.rule_name, rule] }
            @rules = sorted_rules

            @rules.each { |rule| rule.merge(current_rules[rule.rule_name]) }
          end

          OpenTelemetry.logger.debug("Updated sampling rules: #{@rules}")
        end

        # @param [Array<Client::SamplingTargetDocument>] targets
        def update_targets(targets)
          name_to_target = targets.to_h { |target| [target.rule_name, target] }

          @lock.synchronize do
            @rules.each { |rule| rule.with_target(name_to_target[rule.rule_name]) }
          end

          OpenTelemetry.logger.debug("Updated sampling targets: #{@rules}")
        end
      end
    end
  end
end
