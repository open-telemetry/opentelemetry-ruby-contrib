# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'json'

describe OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient do
  DATA_DIR = File.join(__dir__, 'data')
  TEST_URL = '127.0.0.1:2000'

  it 'test_get_no_sampling_rules' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: { SamplingRuleRecords: [] }.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_rules do |response|
      assert_equal 0, response[:SamplingRuleRecords]&.length
    end
  end

  it 'test_get_invalid_response' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: {}.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_rules do |response|
      assert_nil response[:SamplingRuleRecords]&.length
    end
  end

  it 'test_get_sampling_rule_missing_in_records' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: { SamplingRuleRecords: [{}] }.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_rules do |response|
      assert_equal 1, response[:SamplingRuleRecords]&.length
    end
  end

  it 'test_default_values_used_when_missing_properties_in_sampling_rule' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: { SamplingRuleRecords: [{ SamplingRule: {} }] }.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_rules do |response|
      assert_equal 1, response[:SamplingRuleRecords]&.length
      rule = response[:SamplingRuleRecords]&.first&.[](:SamplingRule)
      refute_nil rule
      assert_nil rule[:Attributes]
      assert_nil rule[:FixedRate]
      assert_nil rule[:HTTPMethod]
      assert_nil rule[:Host]
      assert_nil rule[:Priority]
      assert_nil rule[:ReservoirSize]
      assert_nil rule[:ResourceARN]
      assert_nil rule[:RuleARN]
      assert_nil rule[:RuleName]
      assert_nil rule[:ServiceName]
      assert_nil rule[:ServiceType]
      assert_nil rule[:URLPath]
      assert_nil rule[:Version]
    end
  end

  it 'test_get_correct_number_of_sampling_rules' do
    data = JSON.parse(File.read("#{DATA_DIR}/get-sampling-rules-response-sample.json"))
    records = data['SamplingRuleRecords']

    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: data.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_rules do |response|
      assert_equal records.length, response[:SamplingRuleRecords]&.length

      records.each_with_index do |record, i|
        response_rule = response[:SamplingRuleRecords][i][:SamplingRule]
        record_rule = record['SamplingRule']

        assert_equal record_rule['Attributes'], response_rule[:Attributes]
        assert_equal record_rule['FixedRate'], response_rule[:FixedRate]
        assert_equal record_rule['HTTPMethod'], response_rule[:HTTPMethod]
        assert_equal record_rule['Host'], response_rule[:Host]
        assert_equal record_rule['Priority'], response_rule[:Priority]
        assert_equal record_rule['ReservoirSize'], response_rule[:ReservoirSize]
        assert_equal record_rule['ResourceARN'], response_rule[:ResourceARN]
        assert_equal record_rule['RuleARN'], response_rule[:RuleARN]
        assert_equal record_rule['RuleName'], response_rule[:RuleName]
        assert_equal record_rule['ServiceName'], response_rule[:ServiceName]
        assert_equal record_rule['ServiceType'], response_rule[:ServiceType]
        assert_equal record_rule['URLPath'], response_rule[:URLPath]
        assert_equal record_rule['Version'], response_rule[:Version]
      end
    end
  end

  it 'test_get_sampling_targets' do
    data = JSON.parse(File.read("#{DATA_DIR}/get-sampling-targets-response-sample.json"))

    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: data.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_targets(data) do |response|
      assert_equal 2, response[:SamplingTargetDocuments].length
      assert_equal 0, response[:UnprocessedStatistics].length
      assert_equal 1_707_551_387, response[:LastRuleModification]
    end
  end

  it 'test_get_invalid_sampling_targets' do
    data = {
      LastRuleModification: nil,
      SamplingTargetDocuments: nil,
      UnprocessedStatistics: nil
    }

    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: data.to_json)

    client = OpenTelemetry::Sampler::XRay::AWSXRaySamplingClient.new(TEST_URL)

    client.fetch_sampling_targets(data) do |response|
      assert_nil response[:SamplingTargetDocuments]
      assert_nil response[:UnprocessedStatistics]
      assert_nil response[:LastRuleModification]
    end
  end
end
