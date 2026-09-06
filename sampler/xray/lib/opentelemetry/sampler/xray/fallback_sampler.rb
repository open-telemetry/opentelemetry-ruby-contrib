# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'rate_limiting_sampler'

module OpenTelemetry
  module Sampler
    module XRay
      # FallbackSampler samples 1 req/sec and additional 5% of requests using TraceIdRatioBasedSampler.
      class FallbackSampler
        def initialize
          @fixed_rate_sampler = OpenTelemetry::SDK::Trace::Samplers::TraceIdRatioBased.new(0.05)
          @rate_limiting_sampler = RateLimitingSampler.new(1)
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          sampling_result = @rate_limiting_sampler.should_sample?(
            trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes
          )

          return sampling_result if sampling_result.instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP

          @fixed_rate_sampler.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
        end

        def description
          'FallbackSampler{fallback sampling with sampling config of 1 req/sec and 5% of additional requests}'
        end
      end
    end
  end
end
