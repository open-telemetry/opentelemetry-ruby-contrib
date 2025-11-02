# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampler
    module XRay
      # Utils contains utilities for X-Ray Sampling Rule matching logic
      module Utils
        module_function

        CLOUD_PLATFORM_MAPPING = {
          'aws_lambda' => 'AWS::Lambda::Function',
          'aws_elastic_beanstalk' => 'AWS::ElasticBeanstalk::Environment',
          'aws_ec2' => 'AWS::EC2::Instance',
          'aws_ecs' => 'AWS::ECS::Container',
          'aws_eks' => 'AWS::EKS::Container'
        }.freeze

        def escape_regexp(regexp_pattern)
          # Escapes special characters except * and ? to maintain wildcard functionality
          regexp_pattern.gsub(/[.+^${}()|\[\]\\]/) { |match| "\\#{match}" }
        end

        def convert_pattern_to_regexp(pattern)
          escape_regexp(pattern).gsub('*', '.*').tr('?', '.')
        end

        def wildcard_match(pattern = nil, text = nil)
          return true if pattern == '*'
          return false if pattern.nil? || !text.is_a?(String)
          return text.empty? if pattern.empty?

          regexp = "^#{convert_pattern_to_regexp(pattern.downcase)}$"
          match = text.downcase.match?(regexp)

          unless match
            OpenTelemetry.logger.debug(
              "WildcardMatch: no match found for #{text} against pattern #{pattern}"
            )
          end

          match
        end

        def attribute_match?(attributes = nil, rule_attributes = nil)
          return true if rule_attributes.nil? || rule_attributes.empty?

          return false if attributes.nil? ||
                          attributes.empty? ||
                          rule_attributes.length > attributes.length

          matched_count = 0
          attributes.each do |key, value|
            found_key = rule_attributes.keys.find { |rule_key| rule_key == key }
            next if found_key.nil?

            matched_count += 1 if wildcard_match(rule_attributes[found_key], value)
          end

          matched_count == rule_attributes.length
        end
      end
    end
  end
end
