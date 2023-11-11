# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module Hierarchical
      class Sampler
        # @param [Array<OpenTelemetry::SDK::Trace::Samplers>] samplers
        def initialize(*samplers)
          @samplers = samplers
        end

        # @param [String] trace_id
        # @param [OpenTelemetry::Context] parent_context
        # @param [Enumerable<Link>] links
        # @param [String] name
        # @param [Symbol] kind
        # @param [Hash<String, Object>] attributes
        # @return [OpenTelemetry::SDK::Trace::Samplers::Result] The sampling result.
        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          @samplers.each do |sampler|
            result = sampler.should_sample?(
              trace_id: trace_id,
              parent_context: parent_context,
              links: links,
              name: name,
              kind: kind,
              attributes: attributes
            )
            return result if result.sampled?
          end

          OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
            tracestate: OpenTelemetry::Trace.current_span(parent_context).context.tracestate
          )
        end
      end
    end
  end
end
