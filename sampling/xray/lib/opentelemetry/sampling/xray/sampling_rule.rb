# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative('matcher')
require_relative('reservoir')
require_relative('statistic')

module OpenTelemetry
  module Sampling
    module XRay
      class SamplingRule
        AWS_LAMBDA = 'aws_lambda'
        CLOUD_RESOURCE_ID = 'cloud.resource_id'
        XRAY_CLOUD_PLATFORM = {
          'aws_ec2' => 'AWS::EC2::Instance',
          'aws_ecs' => 'AWS::ECS::Container',
          'aws_eks' => 'AWS::EKS::Container',
          'aws_elastic_beanstalk' => 'AWS::ElasticBeanstalk::Environment',
          'aws_lambda' => 'AWS::Lambda::Function'
        }.freeze

        attr_reader(
          :priority,
          :reservoir,
          :rule_name,
          :statistic
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
          @fixed_rate = fixed_rate
          @rule_name = rule_name
          @priority = priority

          @attribute_matchers = attributes.transform_values { |value| Matcher.to_matcher(value) }
          @host_matcher = Matcher.to_matcher(host)
          @http_method_matcher = Matcher.to_matcher(http_method)
          @resource_arn_matcher = Matcher.to_matcher(resource_arn)
          @service_name_matcher = Matcher.to_matcher(service_name)
          @service_type_matcher = Matcher.to_matcher(service_type)
          @url_path_matcher = Matcher.to_matcher(url_path)

          @reservoir = Reservoir.new(reservoir_size)
          @statistic = Statistic.new

          @lock = Mutex.new
        end

        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @param [Hash<String, Object>] attributes
        # @return [Boolean]
        def match?(resource:, attributes:)
          host = attributes&.dig(OpenTelemetry::SemanticConventions::Trace::NET_HOST_NAME) || attributes&.dig(OpenTelemetry::SemanticConventions::Trace::HTTP_HOST)
          http_method = attributes&.dig(OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD)
          http_target = attributes&.dig(OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET)
          http_url = attributes&.dig(OpenTelemetry::SemanticConventions::Trace::HTTP_URL)

          @attribute_matchers.all? { |key, matcher| matcher.match?(attributes&.dig(key)) } &&
            @host_matcher.match?(host) &&
            @http_method_matcher.match?(http_method) &&
            @resource_arn_matcher.match?(get_arn(attributes, resource)) &&
            @service_name_matcher.match?(get_attribute(resource, OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME)) &&
            @service_type_matcher.match?(get_service_type(resource)) &&
            @url_path_matcher.match?(extract_http_target(http_target, http_url))
        end

        # @return [Boolean]
        def can_sample?
          @lock.synchronize do
            @statistic.increment_request_count
            case @reservoir.borrow_or_take?
            when Reservoir::BORROW
              @statistic.increment_borrow_count
              true
            when Reservoir::TAKE
              @statistic.increment_sampled_count
              true
            else
              if rand <= @fixed_rate
                @statistic.increment_sampled_count
                true
              else
                false
              end
            end
          end
        end

        # @return [Boolean]
        def ever_matched?
          @statistic.request_count.positive?
        end

        # @param [SamplingRule] rule
        def merge(rule)
          return if rule.nil? || rule.rule_name != @rule_name

          @statistic = rule.statistic
          @reservoir = rule.reservoir
        end

        # @param [Client::SamplingTargetDocument] target
        def with_target(target)
          return if target.nil? || target.rule_name != @rule_name

          @fixed_rate = target.fixed_rate
          @reservoir.update_target(
            quota: target.reservoir_quota,
            quota_ttl: target.reservoir_quota_ttl
          )
        end

        private

        # @param [String] http_target
        # @param [String] http_url
        # @return [String]
        def extract_http_target(http_target, http_url)
          return http_target if !http_target.nil? || http_url.nil?

          scheme_end_index = http_url.index('://')
          # Per spec, http.url is always populated with scheme://host[:port]/path?query[#fragment]
          return http_target if scheme_end_index.negative?

          path_index = http_url.index('/', scheme_end_index + '://'.length)
          if path_index.negative?
            # No path, equivalent to root path.
            '/'
          else
            http_url[path_index..-1]
          end
        end

        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @return [String]
        def get_service_type(resource)
          cloud_platform = get_attribute(resource, OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM)
          XRAY_CLOUD_PLATFORM[cloud_platform]
        end

        # @param [Hash<String, Object>] attributes
        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @return [String]
        def get_arn(attributes, resource)
          arn = get_attribute(resource, OpenTelemetry::SemanticConventions::Resource::AWS_ECS_CONTAINER_ARN)
          return arn unless arn.nil?

          cloud_platform = get_attribute(resource, OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM)
          return unless cloud_platform == AWS_LAMBDA

          get_lambda_arn(attributes, resource)
        end

        # @param [Hash<String, Object>] attributes
        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @return [String]
        def get_lambda_arn(attributes, resource)
          get_attribute(resource, CLOUD_RESOURCE_ID) || attributes[CLOUD_RESOURCE_ID]
        end

        # @param [OpenTelemetry::SDK::Resources::Resource] resource
        # @param [String] attribute
        # @return [Object]
        def get_attribute(resource, attribute)
          resource.attribute_enumerator.find { |key, _| key == attribute }&.last
        end
      end
    end
  end
end
