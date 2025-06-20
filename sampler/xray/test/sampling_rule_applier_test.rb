# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'json'

describe OpenTelemetry::Sampler::XRay::SamplingRuleApplier do
  DATA_DIR = File.join(File.dirname(__FILE__), 'data')

  it 'test_applier_attribute_matching_from_xray_response' do
    sample_data = JSON.parse(File.read(File.join(DATA_DIR, 'get-sampling-rules-response-sample-2.json')))

    all_rules = sample_data['SamplingRuleRecords']
    default_rule = OpenTelemetry::Sampler::XRay::SamplingRule.new(all_rules[0]['SamplingRule'])
    sampling_rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(default_rule)

    resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                'service.name' => 'test_service_name',
                                                                'cloud.platform' => 'test_cloud_platform'
                                                              })

    attr = {
      'http.target' => '/target',
      'http.method' => 'method',
      'http.url' => 'url',
      'http.host' => 'host',
      'foo' => 'bar',
      'abc' => '1234'
    }

    assert sampling_rule_applier.matches?(attr, resource)
  end

  it 'test_applier_matches_with_all_attributes' do
    rule = OpenTelemetry::Sampler::XRay::SamplingRule.new({
                                                            'Attributes' => { 'abc' => '123', 'def' => '4?6', 'ghi' => '*89' },
                                                            'FixedRate' => 0.11,
                                                            'HTTPMethod' => 'GET',
                                                            'Host' => 'localhost',
                                                            'Priority' => 20,
                                                            'ReservoirSize' => 1,
                                                            'ResourceARN' => 'arn:aws:lambda:us-west-2:123456789012:function:my-function',
                                                            'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
                                                            'RuleName' => 'test',
                                                            'ServiceName' => 'myServiceName',
                                                            'ServiceType' => 'AWS::Lambda::Function',
                                                            'URLPath' => '/helloworld',
                                                            'Version' => 1
                                                          })

    attributes = {
      'http.host' => 'localhost',
      'http.method' => 'GET',
      'aws.lambda.invoked_arn' => 'arn:aws:lambda:us-west-2:123456789012:function:my-function',
      'http.url' => 'http://127.0.0.1:5000/helloworld',
      'abc' => '123',
      'def' => '456',
      'ghi' => '789'
    }

    resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                'service.name' => 'myServiceName',
                                                                'cloud.platform' => 'aws_lambda'
                                                              })

    rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(rule)

    assert rule_applier.matches?(attributes, resource)

    attributes.delete('http.url')
    attributes['http.target'] = '/helloworld'
    assert rule_applier.matches?(attributes, resource)
  end

  it 'test_applier_wild_card_attributes_matches_span_attributes' do
    rule = OpenTelemetry::Sampler::XRay::SamplingRule.new({
                                                            'Attributes' => {
                                                              'attr1' => '*',
                                                              'attr2' => '*',
                                                              'attr3' => 'HelloWorld',
                                                              'attr4' => 'Hello*',
                                                              'attr5' => '*World',
                                                              'attr6' => '?ello*',
                                                              'attr7' => 'Hell?W*d',
                                                              'attr8' => '*.World',
                                                              'attr9' => '*.World'
                                                            },
                                                            'FixedRate' => 0.11,
                                                            'HTTPMethod' => '*',
                                                            'Host' => '*',
                                                            'Priority' => 20,
                                                            'ReservoirSize' => 1,
                                                            'ResourceARN' => '*',
                                                            'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
                                                            'RuleName' => 'test',
                                                            'ServiceName' => '*',
                                                            'ServiceType' => '*',
                                                            'URLPath' => '*',
                                                            'Version' => 1
                                                          })

    rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(rule)

    attributes = {
      'attr1' => '',
      'attr2' => 'HelloWorld',
      'attr3' => 'HelloWorld',
      'attr4' => 'HelloWorld',
      'attr5' => 'HelloWorld',
      'attr6' => 'HelloWorld',
      'attr7' => 'HelloWorld',
      'attr8' => 'Hello.World',
      'attr9' => 'Bye.World'
    }

    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create)
  end

  it 'test_applier_wild_card_attributes_matches_http_span_attributes' do
    rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(
      OpenTelemetry::Sampler::XRay::SamplingRule.new({
                                                       'Attributes' => {},
                                                       'FixedRate' => 0.11,
                                                       'HTTPMethod' => '*',
                                                       'Host' => '*',
                                                       'Priority' => 20,
                                                       'ReservoirSize' => 1,
                                                       'ResourceARN' => '*',
                                                       'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
                                                       'RuleName' => 'test',
                                                       'ServiceName' => '*',
                                                       'ServiceType' => '*',
                                                       'URLPath' => '*',
                                                       'Version' => 1
                                                     })
    )

    attributes = {
      'http.host' => 'localhost',
      'http.method' => 'GET',
      'http.url' => 'http://127.0.0.1:5000/helloworld'
    }

    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create)
  end

  it 'test_applier_wild_card_attributes_matches_with_empty_attributes' do
    rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(
      OpenTelemetry::Sampler::XRay::SamplingRule.new({
                                                       'Attributes' => {},
                                                       'FixedRate' => 0.11,
                                                       'HTTPMethod' => '*',
                                                       'Host' => '*',
                                                       'Priority' => 20,
                                                       'ReservoirSize' => 1,
                                                       'ResourceARN' => '*',
                                                       'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
                                                       'RuleName' => 'test',
                                                       'ServiceName' => '*',
                                                       'ServiceType' => '*',
                                                       'URLPath' => '*',
                                                       'Version' => 1
                                                     })
    )

    attributes = {}
    resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                'service.name' => 'myServiceName',
                                                                'cloud.platform' => 'aws_ec2'
                                                              })

    assert rule_applier.matches?(attributes, resource)
    assert rule_applier.matches?({}, resource)
    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create)
    assert rule_applier.matches?({}, OpenTelemetry::SDK::Resources::Resource.create)
    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create({}))
    assert rule_applier.matches?({}, OpenTelemetry::SDK::Resources::Resource.create({}))
  end

  it 'test_applier_matches_with_http_url_with_http_target_undefined' do
    rule_applier = OpenTelemetry::Sampler::XRay::SamplingRuleApplier.new(
      OpenTelemetry::Sampler::XRay::SamplingRule.new({
                                                       'Attributes' => {},
                                                       'FixedRate' => 0.11,
                                                       'HTTPMethod' => '*',
                                                       'Host' => '*',
                                                       'Priority' => 20,
                                                       'ReservoirSize' => 1,
                                                       'ResourceARN' => '*',
                                                       'RuleARN' => 'arn:aws:xray:us-east-1:999999999999:sampling-rule/test',
                                                       'RuleName' => 'test',
                                                       'ServiceName' => '*',
                                                       'ServiceType' => '*',
                                                       'URLPath' => '/somerandompath',
                                                       'Version' => 1
                                                     })
    )

    attributes = {
      'http.url' => 'https://somerandomurl.com/somerandompath'
    }
    resource = OpenTelemetry::SDK::Resources::Resource.create({})

    assert rule_applier.matches?(attributes, resource)
    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create)
    assert rule_applier.matches?(attributes, OpenTelemetry::SDK::Resources::Resource.create({}))
  end
end
