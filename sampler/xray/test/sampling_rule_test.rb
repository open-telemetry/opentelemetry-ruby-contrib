# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::SamplingRule do
  it 'test_sampling_rule_equality' do
    rule = OpenTelemetry::Sampler::XRay::SamplingRule.new(
      'Attributes' => { 'abc' => '123', 'def' => '4?6', 'ghi' => '*89' },
      'FixedRate' => 0.11,
      'HTTPMethod' => 'GET',
      'Host' => 'localhost',
      'Priority' => 20,
      'ReservoirSize' => 1,
      'ResourceARN' => '*',
      'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
      'RuleName' => 'test',
      'ServiceName' => 'myServiceName',
      'ServiceType' => 'AWS::EKS::Container',
      'URLPath' => '/helloworld',
      'Version' => 1
    )

    rule_unordered_attributes = OpenTelemetry::Sampler::XRay::SamplingRule.new(
      'Attributes' => { 'ghi' => '*89', 'abc' => '123', 'def' => '4?6' },
      'FixedRate' => 0.11,
      'HTTPMethod' => 'GET',
      'Host' => 'localhost',
      'Priority' => 20,
      'ReservoirSize' => 1,
      'ResourceARN' => '*',
      'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
      'RuleName' => 'test',
      'ServiceName' => 'myServiceName',
      'ServiceType' => 'AWS::EKS::Container',
      'URLPath' => '/helloworld',
      'Version' => 1
    )

    rule_updated = OpenTelemetry::Sampler::XRay::SamplingRule.new(
      'Attributes' => { 'ghi' => '*89', 'abc' => '123', 'def' => '4?6' },
      'FixedRate' => 0.11,
      'HTTPMethod' => 'GET',
      'Host' => 'localhost',
      'Priority' => 20,
      'ReservoirSize' => 1,
      'ResourceARN' => '*',
      'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
      'RuleName' => 'test',
      'ServiceName' => 'myServiceName',
      'ServiceType' => 'AWS::EKS::Container',
      'URLPath' => '/helloworld_new',
      'Version' => 1
    )

    rule_updated_two = OpenTelemetry::Sampler::XRay::SamplingRule.new(
      'Attributes' => { 'abc' => '128', 'def' => '4?6', 'ghi' => '*89' },
      'FixedRate' => 0.11,
      'HTTPMethod' => 'GET',
      'Host' => 'localhost',
      'Priority' => 20,
      'ReservoirSize' => 1,
      'ResourceARN' => '*',
      'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
      'RuleName' => 'test',
      'ServiceName' => 'myServiceName',
      'ServiceType' => 'AWS::EKS::Container',
      'URLPath' => '/helloworld',
      'Version' => 1
    )

    assert_equal true, rule.equals?(rule_unordered_attributes)
    assert_equal false, rule.equals?(rule_updated)
    assert_equal false, rule.equals?(rule_updated_two)
  end
end
