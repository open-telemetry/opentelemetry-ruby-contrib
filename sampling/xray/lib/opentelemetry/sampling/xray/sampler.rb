# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Sampler
        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @param [OpenTelemetry::SDK::Trace::Samplers] fallback_sampler
        def initialize(resource:, fallback_sampler:)
          raise(ArgumentError, 'resource must not be nil') if resource.nil?
          raise(ArgumentError, 'fallback_sampler must not be nil') if fallback_sampler.nil?

          @resource = resource
          @fallback_sampler = fallback_sampler
        end

        # @param [String] trace_id
        # @param [OpenTelemetry::Context] parent_context
        # @param [Enumerable<Link>] links
        # @param [String] name
        # @param [Symbol] kind
        # @param [Hash<String, Object>] attributes
        # @return [OpenTelemetry::SDK::Trace::Samplers::Result]
        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          @fallback_sampler.should_sample?(
            trace_id: trace_id,
            parent_context: parent_context,
            links: links,
            name: name,
            kind: kind,
            attributes: attributes
          )
        end
      end
    end
  end
end