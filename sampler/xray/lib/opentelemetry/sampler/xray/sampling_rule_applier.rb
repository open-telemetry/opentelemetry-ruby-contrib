# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry-semantic_conventions'
require 'date'
require_relative 'statistics'
require_relative 'utils'

module OpenTelemetry
  module Sampler
    module XRay
      # SamplingRuleApplier is responsible for applying Reservoir Sampling and Probability Sampling
      # from the Sampling Rule when determining the sampling decision for spans that matched the rule
      class SamplingRuleApplier
        attr_reader :sampling_rule

        MAX_DATE_TIME_SECONDS = Time.at(8_640_000_000_000)

        def initialize(sampling_rule, statistics = OpenTelemetry::Sampler::XRay::Statistics.new, target = nil)
          @sampling_rule = sampling_rule
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
            tracestate: OpenTelemetry::Trace::Tracestate::DEFAULT
          )
        end
      end
    end
  end
end
