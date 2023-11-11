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
          @rules.find { |rule| rule.match?(resource: resource, attributes: attributes) }
        end

        # @param [Array<SamplingRule>] rules
        def update_rules(rules)
          @lock.synchronize do
            @rules = rules.sort_by { |rule| [rule.priority, rule.rule_name] }
          end

          OpenTelemetry.logger.debug("Updated sampling rules: #{@rules}")
        end
      end
    end
  end
end
