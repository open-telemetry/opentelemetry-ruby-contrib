# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('json')
require('net/http')
require('time')
require_relative('sampling_rule')

module OpenTelemetry
  module Sampling
    module XRay
      class Client
        # @param [String] endpoint
        def initialize(endpoint:)
          @endpoint = endpoint
          @client_id = SecureRandom.hex(12)
          OpenTelemetry.logger.info("Initialized X-Ray client with endpoint '#{@endpoint}' and client ID '#{@client_id}'")
        end

        # @return [Array<SamplingRuleRecord>]
        def fetch_sampling_rules
          post(path: '/GetSamplingRules')
            .fetch(:SamplingRuleRecords, [])
            .map { |item| SamplingRuleRecord.from_response(item) }
        end

        # @param [Array<SamplingRule>] sampling_rules
        # @return [SamplingTargetResponse]
        def fetch_sampling_targets(sampling_rules)
          OpenTelemetry.logger.debug("Fetching sampling targets for rules: #{sampling_rules}")

          response = post(
            path: '/SamplingTargets',
            body: {
              SamplingStatisticsDocuments: sampling_rules.map { |rule| SamplingStatisticsDocument.from_rule(rule, @client_id) }.map(&:to_request)
            }
          )
          SamplingTargetResponse.from_response(response)
        end

        private

        # @param [String] path
        # @param [Hash] body
        # @return [Hash]
        def post(path:, body: nil)
          response = Net::HTTP.post(URI("#{@endpoint}#{path}"), body&.to_json)

          raise("Received #{response.code} (#{response.message}): #{response.body}") unless response.is_a?(Net::HTTPSuccess)

          OpenTelemetry.logger.debug("X-Ray response for #{path}: #{response.body}")
          JSON.parse(response.body, symbolize_names: true)
        rescue StandardError => e
          OpenTelemetry.logger.error("Error while posting to X-Ray: #{e.message}")
          {}
        end

        class SamplingRuleRecord
          attr_reader(:sampling_rule)

          # @param [SamplingRule] sampling_rule
          # @param [Time] created_at
          # @param [Time] modified_at
          def initialize(sampling_rule:, created_at:, modified_at:)
            @sampling_rule = sampling_rule
            @created_at = created_at
            @modified_at = modified_at
          end

          # @param [Hash] response
          # @return [SamplingRuleRecord]
          def self.from_response(response)
            SamplingRuleRecord.new(
              sampling_rule: SamplingRule.new(
                attributes: response[:SamplingRule][:Attributes],
                fixed_rate: response[:SamplingRule][:FixedRate],
                host: response[:SamplingRule][:Host],
                http_method: response[:SamplingRule][:HTTPMethod],
                priority: response[:SamplingRule][:Priority],
                reservoir_size: response[:SamplingRule][:ReservoirSize],
                resource_arn: response[:SamplingRule][:ResourceARN],
                rule_arn: response[:SamplingRule][:RuleARN],
                rule_name: response[:SamplingRule][:RuleName],
                service_name: response[:SamplingRule][:ServiceName],
                service_type: response[:SamplingRule][:ServiceType],
                url_path: response[:SamplingRule][:URLPath],
                version: response[:SamplingRule][:Version]
              ),
              created_at: Time.at(response[:CreatedAt]),
              modified_at: Time.at(response[:ModifiedAt])
            )
          end
        end

        class SamplingStatisticsDocument
          # @param [String] rule_name
          # @param [String] client_id
          # @param [Time] timestamp
          # @param [Integer] request_count
          # @param [Integer] sampled_count
          # @param [Integer] borrow_count
          def initialize(
            rule_name:,
            client_id:,
            timestamp:,
            request_count:,
            sampled_count:,
            borrow_count:
          )
            @rule_name = rule_name
            @client_id = client_id
            @timestamp = timestamp
            @request_count = request_count
            @sampled_count = sampled_count
            @borrow_count = borrow_count
          end

          # @return [Hash]
          def to_request
            {
              RuleName: @rule_name,
              ClientID: @client_id,
              Timestamp: @timestamp.to_i,
              RequestCount: @request_count,
              SampledCount: @sampled_count,
              BorrowCount: @borrow_count
            }
          end

          # @param [Object] other
          # @return [Boolean]
          def ==(other)
            other.is_a?(SamplingStatisticsDocument) && to_request == other.to_request
          end

          # @param [SamplingRule] rule
          # @param [String] client_id
          # @return [SamplingStatisticsDocument]
          def self.from_rule(rule, client_id)
            statistic = rule.snapshot_statistic

            SamplingStatisticsDocument.new(
              rule_name: rule.rule_name,
              client_id: client_id,
              timestamp: Time.now,
              request_count: statistic.request_count,
              sampled_count: statistic.sampled_count,
              borrow_count: statistic.borrow_count
            )
          end
        end

        class SamplingTargetDocument
          attr_reader(
            :rule_name,
            :fixed_rate,
            :reservoir_quota,
            :reservoir_quota_ttl,
            :interval
          )

          # @param [String] rule_name
          # @param [Float] fixed_rate
          # @param [Integer] reservoir_quota
          # @param [Integer] reservoir_quota_ttl
          # @param [Integer] interval
          def initialize(
            rule_name:,
            fixed_rate:,
            reservoir_quota:,
            reservoir_quota_ttl:,
            interval:
          )
            @rule_name = rule_name
            @fixed_rate = fixed_rate
            @reservoir_quota = reservoir_quota
            @reservoir_quota_ttl = reservoir_quota_ttl
            @interval = interval
          end

          # @param [Hash] response
          # @return [SamplingTargetDocument]
          def self.from_response(response)
            SamplingTargetDocument.new(
              rule_name: response[:RuleName],
              fixed_rate: response[:FixedRate],
              reservoir_quota: response[:ReservoirQuota],
              reservoir_quota_ttl: response[:ReservoirQuotaTTL],
              interval: response[:Interval]
            )
          end
        end

        class SamplingTargetResponse
          attr_reader(:last_rule_modification, :sampling_target_documents)

          def initialize(last_rule_modification:, sampling_target_documents:)
            @last_rule_modification = last_rule_modification
            @sampling_target_documents = sampling_target_documents
          end

          # @param [Hash] response
          # @return [SamplingTargetResponse]
          def self.from_response(response)
            return nil if response.empty?

            SamplingTargetResponse.new(
              last_rule_modification: Time.at(response[:LastRuleModification]),
              sampling_target_documents: response[:SamplingTargetDocuments].map { |item| SamplingTargetDocument.from_response(item) }
            )
          end
        end
      end
    end
  end
end
