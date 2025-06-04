# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampler
    module XRay
      # FallbackSampler samples 1 req/sec and additional 5% of requests using TraceIdRatioBasedSampler.
      class FallbackSampler
        def initialize
          @fixed_rate_sampler = OpenTelemetry::SDK::Trace::Samplers::TraceIdRatioBased.new(0.05)
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          # TODO: implement and use Rate Limiting Sampler

          @fixed_rate_sampler.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
        end

        def description
          'FallbackSampler{fallback sampling with sampling config of 1 req/sec and 5% of additional requests}'
        end
      end
    end
  end
end
