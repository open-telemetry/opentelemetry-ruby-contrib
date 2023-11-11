# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class SamplingRule
        attr_reader(
          :priority,
          :rule_name
        )

        # @param [Hash] attributes
        # @param [Float] fixed_rate
        # @param [String] host
        # @param [String] http_method
        # @param [Integer] priority
        # @param [Integer] reservoir_size
        # @param [String] resource_arn
        # @param [String] rule_arn
        # @param [String] rule_name
        # @param [String] service_name
        # @param [String] service_type
        # @param [String] url_path
        # @param [Integer] version
        def initialize(
          attributes:,
          fixed_rate:,
          host:,
          http_method:,
          priority:,
          reservoir_size:,
          resource_arn:,
          rule_arn:,
          rule_name:,
          service_name:,
          service_type:,
          url_path:,
          version:
        )
          @rule_name = rule_name
          @priority = priority
        end

        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @param [Hash<String, Object>] attributes
        # @return [Boolean]
        def matches?(resource:, attributes:)
          raise(NotImplementedError)
        end

        # @param [String] trace_id
        # @param [OpenTelemetry::Context] parent_context
        # @param [Enumerable<Link>] links
        # @param [String] name
        # @param [Symbol] kind
        # @param [Hash<String, Object>] attributes
        # @return [OpenTelemetry::SDK::Trace::Samplers::Result]
        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          raise(NotImplementedError)
        end
      end
    end
  end
end
