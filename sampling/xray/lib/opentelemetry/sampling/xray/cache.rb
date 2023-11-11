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
