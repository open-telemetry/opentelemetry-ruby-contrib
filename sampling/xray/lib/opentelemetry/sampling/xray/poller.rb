# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Poller
        # @param [Client] client
        # @param [Cache] cache
        # @param [Integer] rule_interval
        # @param [Integer] target_interval
        def initialize(client:, cache:, rule_interval:, target_interval:)
          @cache = cache
          @client = client
          @rule_interval = rule_interval
          @running = false
          @target_interval = target_interval
        end

        def start
          return if @running

          @running = true
          start_worker
          OpenTelemetry.logger.debug('Started polling')
        end

        def stop
          @running = false
          OpenTelemetry.logger.debug('Stopped polling')
        end

        private

        def start_worker
          refresh_rules

          Thread.new do
            while @running
              sleep_time = @target_interval + rand
              sleep(sleep_time)
              @rule_interval_elapsed += sleep_time

              refresh_rules if @rule_interval_elapsed >= @rule_interval
            end
          end
        end

        def refresh_rules
          OpenTelemetry.logger.debug('Refreshing sampling rules')
          @cache.update_rules(@client.fetch_sampling_rules)
          @rule_interval_elapsed = 0
        end
      end
    end
  end
end
