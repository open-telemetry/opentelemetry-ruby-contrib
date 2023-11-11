# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')

describe(OpenTelemetry::Sampling::XRay::Client) do
  before { WebMock.disable_net_connect! }
  after { WebMock.allow_net_connect! }

  describe('#fetch_sampling_rules') do
    describe('should return an empty array if there are no sampling rules') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }

      before do
        stub_request(:post, "#{endpoint}/GetSamplingRules")
          .to_return(
            body: { SamplingRuleRecords: [] }.to_json,
            headers: { content_type: 'application/json' }
          )
      end
      it do
        rules = OpenTelemetry::Sampling::XRay::Client
                .new(endpoint: endpoint)
                .fetch_sampling_rules

        _(rules).must_equal([])
      end
    end

    describe('should return an empty array if the request results in an error') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }

      before do
        stub_request(:post, "#{endpoint}/GetSamplingRules")
          .to_return(status: 500)
      end
      it do
        rules = OpenTelemetry::Sampling::XRay::Client
                .new(endpoint: endpoint)
                .fetch_sampling_rules

        _(rules).must_equal([])
      end
    end

    describe('should return the sampling rules') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }
      let(:record) do
        {
          Attributes: { SecureRandom.uuid.to_s.to_sym => SecureRandom.uuid.to_s },
          FixedRate: rand,
          Host: SecureRandom.uuid.to_s,
          HTTPMethod: SecureRandom.uuid.to_s,
          Priority: rand,
          ReservoirSize: rand,
          ResourceARN: SecureRandom.uuid.to_s,
          RuleARN: SecureRandom.uuid.to_s,
          RuleName: SecureRandom.uuid.to_s,
          ServiceName: SecureRandom.uuid.to_s,
          ServiceType: SecureRandom.uuid.to_s,
          URLPath: SecureRandom.uuid.to_s,
          Version: rand
        }
      end

      before do
        stub_request(:post, "#{endpoint}/GetSamplingRules")
          .to_return(
            body: {
              SamplingRuleRecords: [
                {
                  SamplingRule: record,
                  CreatedAt: Time.now.to_i,
                  ModifiedAt: Time.now.to_i
                }
              ]
            }.to_json,
            headers: { content_type: 'application/json' }
          )
      end
      it do
        rules = OpenTelemetry::Sampling::XRay::Client
                .new(endpoint: endpoint)
                .fetch_sampling_rules

        _(rules.size).must_equal(1)

        rule = rules.first.sampling_rule
        _(rule.priority).must_equal(record[:Priority])
        _(rule.rule_name).must_equal(record[:RuleName])
      end
    end
  end

  describe('#fetch_sampling_targets') do
    describe('should return an empty array if there are no sampling targets') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }

      before do
        stub_request(:post, "#{endpoint}/SamplingTargets")
          .to_return(
            body: { SamplingTargetDocuments: [] }.to_json,
            headers: { content_type: 'application/json' }
          )
      end
      it do
        rules = OpenTelemetry::Sampling::XRay::Client
                .new(endpoint: endpoint)
                .fetch_sampling_targets([])

        _(rules).must_equal([])
      end
    end

    describe('should return an empty array if the request results in an error') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }

      before do
        stub_request(:post, "#{endpoint}/SamplingTargets")
          .to_return(status: 500)
      end
      it do
        rules = OpenTelemetry::Sampling::XRay::Client
                .new(endpoint: endpoint)
                .fetch_sampling_targets([])

        _(rules).must_equal([])
      end
    end

    describe('should return the sampling rules') do
      let(:endpoint) { "http://#{SecureRandom.uuid}" }
      let(:document) do
        {
          FixedRate: rand,
          Interval: rand,
          ReservoirQuota: rand,
          ReservoirQuotaTTL: rand,
          RuleName: SecureRandom.uuid.to_s
        }
      end

      before do
        stub_request(:post, "#{endpoint}/SamplingTargets")
          .to_return(
            body: { SamplingTargetDocuments: [document] }.to_json,
            headers: { content_type: 'application/json' }
          )
      end
      it do
        targets = OpenTelemetry::Sampling::XRay::Client
                  .new(endpoint: endpoint)
                  .fetch_sampling_targets([])

        _(targets.size).must_equal(1)

        target = targets.first
        _(target.fixed_rate).must_equal(document[:FixedRate])
        _(target.interval).must_equal(document[:Interval])
        _(target.reservoir_quota).must_equal(document[:ReservoirQuota])
        _(target.reservoir_quota_ttl).must_equal(document[:ReservoirQuotaTTL])
        _(target.rule_name).must_equal(document[:RuleName])
      end
    end
  end
end
