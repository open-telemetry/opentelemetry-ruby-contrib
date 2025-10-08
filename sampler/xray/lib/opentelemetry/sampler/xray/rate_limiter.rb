# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampler
    module XRay
      # RateLimiter keeps track of the current reservoir quota balance available (measured via available time)
      # If enough time has elapsed, the RateLimiter will allow quota balance to be consumed/taken (decrease available time)
      # A RateLimitingSampler uses this RateLimiter to determine if it should sample or not based on the quota balance available.
      class RateLimiter
        def initialize(quota, max_balance_in_seconds = 1)
          @max_balance_millis = max_balance_in_seconds * 1000.0
          @quota = quota
          @wallet_floor_millis = Time.now.to_f * 1000
          # current "balance" would be `ceiling - floor`
          @lock = Mutex.new
        end

        def take(cost = 1)
          return false if @quota <= 0

          quota_per_millis = @quota / 1000.0

          # assume divide by zero not possible
          cost_in_millis = cost / quota_per_millis

          @lock.synchronize do
            wallet_ceiling_millis = Time.now.to_f * 1000
            current_balance_millis = wallet_ceiling_millis - @wallet_floor_millis
            current_balance_millis = [current_balance_millis, @max_balance_millis].min
            pending_remaining_balance_millis = current_balance_millis - cost_in_millis

            if pending_remaining_balance_millis >= 0
              @wallet_floor_millis = wallet_ceiling_millis - pending_remaining_balance_millis
              return true
            end

            # No changes to the wallet state
            false
          end
        end
      end
    end
  end
end
