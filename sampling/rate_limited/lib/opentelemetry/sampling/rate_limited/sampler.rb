# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module RateLimited
      class Sampler
        def initialize(credits_per_second)
          @credits_per_second = credits_per_second
          @balance = 0
          @last_tick = get_tick
          @lock = Mutex.new
        end

        # @param [String] trace_id
        # @param [OpenTelemetry::Context] parent_context
        # @param [Enumerable<Link>] links
        # @param [String] name
        # @param [Symbol] kind
        # @param [Hash<String, Object>] attributes
        # @return [OpenTelemetry::SDK::Trace::Samplers::Result] The sampling result.
        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          if can_spend?
            OpenTelemetry::SDK::Trace::Samplers::Result.new(
              decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE,
              tracestate: OpenTelemetry::Trace.current_span(parent_context).context.tracestate
            )
          else
            OpenTelemetry::SDK::Trace::Samplers::Result.new(
              decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
              tracestate: OpenTelemetry::Trace.current_span(parent_context).context.tracestate
            )
          end
        end

        private

        # @return [Boolean]
        def can_spend?
          return false if @credits_per_second <= 0

          @lock.synchronize do
            tick = get_tick
            if tick != @last_tick
              @balance = 0
              @last_tick = tick
            end

            if @balance < @credits_per_second
              @balance += 1
              true
            else
              false
            end
          end
        end

        # @return [Integer]
        def get_tick
          Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i
        end
      end
    end
  end
end
