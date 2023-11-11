# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Reservoir
        BORROW = :borrow
        TAKE = :take

        # @param [Integer] size
        def initialize(size)
          @current_tick = nil
          @quota = nil
          @quota_ttl = nil
          @size = size
        end

        # @return [Symbol, Boolean]
        def borrow_or_take?
          tick = Time.now.to_i
          advance_tick(tick)

          if quota_applicable?(tick)
            return false unless can_take?

            @taken += 1
            return TAKE
          end

          return false unless can_borrow?

          @borrowed += 1
          BORROW
        end

        # @param [Integer] quota
        # @param [Integer] quota_ttl
        def update_target(quota:, quota_ttl:)
          @quota = quota
          @quota_ttl = quota_ttl
        end

        private

        # @param [Integer] tick
        def advance_tick(tick)
          return if @current_tick == tick

          @borrowed = 0
          @current_tick = tick
          @taken = 0
        end

        # @return [Boolean]
        def can_borrow?
          @size.positive? && @borrowed < 1
        end

        # @param [Integer] tick
        # @return [Boolean]
        def quota_applicable?(tick)
          @quota && @quota >= 0 && @quota_ttl && @quota_ttl >= tick
        end

        # @return [Boolean]
        def can_take?
          @taken < @quota
        end
      end
    end
  end
end
