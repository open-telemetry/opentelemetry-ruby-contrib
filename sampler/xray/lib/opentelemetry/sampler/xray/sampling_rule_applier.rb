# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry-semantic_conventions'
require 'date'
require_relative 'sampling_rule'
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
        SEMCONV = OpenTelemetry::SemanticConventions

        def initialize(sampling_rule, statistics = OpenTelemetry::Sampler::XRay::Statistics.new, target = nil)
          @sampling_rule = sampling_rule
          @fixed_rate_sampler = OpenTelemetry::SDK::Trace::Samplers::TraceIdRatioBased.new(@sampling_rule.fixed_rate)

          # TODO: Add Reservoir Sampler (Rate Limiting Sampler)

          @reservoir_expiry_time = MAX_DATE_TIME_SECONDS
          @statistics = statistics
        end

        def matches?(attributes, resource)
          http_target = nil
          http_url = nil
          http_method = nil
          http_host = nil

          unless attributes.nil?
            http_target = attributes[SEMCONV::Trace::HTTP_TARGET]
            http_url = attributes[SEMCONV::Trace::HTTP_URL]
            http_method = attributes[SEMCONV::Trace::HTTP_METHOD]
            http_host = attributes[SEMCONV::Trace::HTTP_HOST]
          end

          service_type = nil
          resource_arn = nil

          resource_hash = resource.attribute_enumerator.to_h

          if resource
            service_name = resource_hash[SEMCONV::Resource::SERVICE_NAME] || ''
            cloud_platform = resource_hash[SEMCONV::Resource::CLOUD_PLATFORM]
            service_type = OpenTelemetry::Sampler::XRay::Utils::CLOUD_PLATFORM_MAPPING[cloud_platform] if cloud_platform.is_a?(String)
            resource_arn = get_arn(resource, attributes)
          end

          if http_target.nil? && http_url.is_a?(String)
            begin
              uri = URI(http_url)
              http_target = uri.path.empty? ? '/' : uri.path
            rescue URI::InvalidURIError
              http_target = '/'
            end
          elsif http_target.nil? && http_url.nil?
            http_target = '/'
          end

          OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attributes, @sampling_rule.attributes) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.host, http_host) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.http_method, http_method) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.service_name, service_name) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.url_path, http_target) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.service_type, service_type) &&
            OpenTelemetry::Sampler::XRay::Utils.wildcard_match(@sampling_rule.resource_arn, resource_arn)
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          # TODO: Record Sampling Statistics

          result = OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
            tracestate: OpenTelemetry::Trace::Tracestate::DEFAULT
          )

          # TODO: Apply Reservoir Sampling

          if result.instance_variable_get(:@decision) == OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
            result = @fixed_rate_sampler.should_sample?(
              trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes
            )
          end

          result
        end

        private

        def get_arn(resource, attributes)
          resource_hash = resource.attribute_enumerator.to_h
          arn = resource_hash[SEMCONV::Resource::AWS_ECS_CONTAINER_ARN] ||
                resource_hash[SEMCONV::Resource::AWS_ECS_CLUSTER_ARN] ||
                resource_hash[SEMCONV::Resource::AWS_EKS_CLUSTER_ARN]

          arn = attributes[SEMCONV::Trace::AWS_LAMBDA_INVOKED_ARN] || resource_hash[SEMCONV::Resource::FAAS_ID] if arn.nil?
          arn
        end
      end
    end
  end
end
