# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampler
    module XRay
      # RuleCache stores all the Sampling Rule Appliers, each corresponding
      # to the user's Sampling Rules that were retrieved from AWS X-Ray
      class RuleCache
        # The cache expires 1 hour after the last refresh time.
        RULE_CACHE_TTL_MILLIS = 60 * 60 * 1000

        def initialize(sampler_resource)
          @rule_appliers = []
          @sampler_resource = sampler_resource
          @last_updated_epoch_millis = Time.now.to_i * 1000
          @cache_lock = Mutex.new
        end

        def expired?
          now_in_millis = Time.now.to_i * 1000
          now_in_millis > @last_updated_epoch_millis + RULE_CACHE_TTL_MILLIS
        end

        def get_matched_rule(attributes)
          @rule_appliers.find do |rule|
            rule.matches?(attributes, @sampler_resource) || rule.sampling_rule.rule_name == 'Default'
          end
        end

        def update_rules(new_rule_appliers)
          old_rule_appliers_map = {}

          @cache_lock.synchronize do
            @rule_appliers.each do |rule|
              old_rule_appliers_map[rule.sampling_rule.rule_name] = rule
            end

            new_rule_appliers.each_with_index do |new_rule, index|
              rule_name_to_check = new_rule.sampling_rule.rule_name
              next unless old_rule_appliers_map.key?(rule_name_to_check)

              old_rule = old_rule_appliers_map[rule_name_to_check]
              new_rule_appliers[index] = old_rule if new_rule.sampling_rule.equals?(old_rule.sampling_rule)
            end

            @rule_appliers = new_rule_appliers
            sort_rules_by_priority
            @last_updated_epoch_millis = Time.now.to_i * 1000
          end
        end

        def create_sampling_statistics_documents(client_id)
          statistics_documents = []

          @cache_lock.synchronize do
            @rule_appliers.each do |rule|
              statistics = rule.snapshot_statistics
              now_in_seconds = Time.now.to_i

              sampling_statistics_doc = {
                ClientID: client_id,
                RuleName: rule.sampling_rule.rule_name,
                Timestamp: now_in_seconds,
                RequestCount: statistics.request_count,
                BorrowCount: statistics.borrow_count,
                SampledCount: statistics.sample_count
              }

              statistics_documents << sampling_statistics_doc
            end
          end

          statistics_documents
        end

        def update_targets(target_documents, last_rule_modification)
          min_polling_interval = nil
          next_polling_interval = DEFAULT_TARGET_POLLING_INTERVAL_SECONDS

          @cache_lock.synchronize do
            @rule_appliers.each_with_index do |rule, index|
              target = target_documents[rule.sampling_rule.rule_name]
              if target
                @rule_appliers[index] = rule.with_target(target)
                min_polling_interval = target['Interval'] if target['Interval'] && (min_polling_interval.nil? || min_polling_interval > target['Interval'])
              else
                OpenTelemetry.logger.debug('Invalid sampling target: missing rule name')
              end
            end

            next_polling_interval = min_polling_interval if min_polling_interval

            refresh_sampling_rules = last_rule_modification * 1000 > @last_updated_epoch_millis
            return [refresh_sampling_rules, next_polling_interval]
          end
        end

        private

        def sort_rules_by_priority
          @rule_appliers.sort! do |rule1, rule2|
            if rule1.sampling_rule.priority == rule2.sampling_rule.priority
              rule1.sampling_rule.rule_name < rule2.sampling_rule.rule_name ? -1 : 1
            else
              rule1.sampling_rule.priority - rule2.sampling_rule.priority
            end
          end
        end
      end
    end
  end
end
