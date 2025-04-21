# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'net/http'
require 'json'
require 'opentelemetry/sdk'
require_relative 'sampling_rule'
require_relative 'sampling_rule_applier'
require_relative 'aws_xray_sampling_client'

module OpenTelemetry
  module Sampler
    module XRay
      # Constants
      DEFAULT_RULES_POLLING_INTERVAL_SECONDS = 5 * 60
      DEFAULT_TARGET_POLLING_INTERVAL_SECONDS = 10
      DEFAULT_AWS_PROXY_ENDPOINT = 'http://localhost:2000'

      # AWSXRayRemoteSampler is a Wrapper class to ensure that all XRay Sampler Functionality
      # in InternalAWSXRayRemoteSampler uses ParentBased logic to respect the parent span's sampling decision
      class AWSXRayRemoteSampler
        def initialize(endpoint: '127.0.0.1:2000', polling_interval: DEFAULT_RULES_POLLING_INTERVAL_SECONDS, resource: OpenTelemetry::SDK::Resources::Resource.create)
          @root = OpenTelemetry::SDK::Trace::Samplers.parent_based(
            root: OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.new(endpoint: endpoint, polling_interval: polling_interval, resource: resource)
          )
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          @root.should_sample?(
            trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes
          )
        end

        def description
          "AWSXRayRemoteSampler{root=#{@root.description}}"
        end
      end

      # InternalAWSXRayRemoteSampler contains all core XRay Sampler Functionality,
      # however it is NOT Parent-based (e.g. Sample logic runs for each span)
      class InternalAWSXRayRemoteSampler
        def initialize(endpoint: '127.0.0.1:2000', polling_interval: DEFAULT_RULES_POLLING_INTERVAL_SECONDS, resource: OpenTelemetry::SDK::Resources::Resource.create)
          if polling_interval.nil? || polling_interval < 10
            OpenTelemetry.logger.warn(
              "'polling_interval' is undefined or too small. Defaulting to #{DEFAULT_RULES_POLLING_INTERVAL_SECONDS} seconds"
            )
            @rule_polling_interval_millis = DEFAULT_RULES_POLLING_INTERVAL_SECONDS * 1000
          else
            @rule_polling_interval_millis = polling_interval * 1000
          end

          @rule_polling_jitter_millis = rand * 5 * 1000
          @target_polling_interval = DEFAULT_TARGET_POLLING_INTERVAL_SECONDS
          @target_polling_jitter_millis = (rand / 10) * 1000

          @aws_proxy_endpoint = endpoint || DEFAULT_AWS_PROXY_ENDPOINT
          @client_id = self.class.generate_client_id

          @sampling_client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(@aws_proxy_endpoint)

          # Start the Sampling Rules poller
          start_sampling_rules_poller

          # TODO: Start the Sampling Targets poller
        end

        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          OpenTelemetry::SDK::Trace::Samplers::Result.new(
            decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
            tracestate: tracestate,
            attributes: attributes
          )
        end

        def description
          "InternalAWSXRayRemoteSampler{aws_proxy_endpoint=#{@aws_proxy_endpoint}, rule_polling_interval_millis=#{@rule_polling_interval_millis}}"
        end

        private

        def start_sampling_rules_poller
          # Execute first update
          retrieve_and_update_sampling_rules

          # Update sampling rules periodically
          @rule_poller = Thread.new do
            loop do
              sleep((@rule_polling_interval_millis + @rule_polling_jitter_millis) / 1000.0)
              retrieve_and_update_sampling_rules
            end
          end
        end

        def retrieve_and_update_sampling_rules
          sampling_rules_response = @sampling_client.fetch_sampling_rules
          if sampling_rules_response&.body && sampling_rules_response.body != ''
            rules = JSON.parse(sampling_rules_response.body)
            update_sampling_rules(rules)
          else
            OpenTelemetry.logger.error('GetSamplingRules Response is falsy')
          end
        end

        def update_sampling_rules(response_object)
          sampling_rules = []
          if response_object && response_object['SamplingRuleRecords']
            response_object['SamplingRuleRecords'].each do |record|
              if record['SamplingRule']
                sampling_rule = OpenTelemetry::Sampler::XRay::SamplingRule.new(record['SamplingRule'])
                sampling_rules << SamplingRuleApplier.new(sampling_rule)
              end
            end
            # TODO: Add Sampling Rules to a Rule Cache
          else
            OpenTelemetry.logger.error('SamplingRuleRecords from GetSamplingRules request is not defined')
          end
        end

        class << self
          def generate_client_id
            hex_chars = ('0'..'9').to_a + ('a'..'f').to_a
            Array.new(24) { hex_chars.sample }.join
          end
        end
      end
    end
  end
end
