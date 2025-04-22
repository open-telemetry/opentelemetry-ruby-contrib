# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

DATA_DIR_SAMPLING_RULES = File.join(__dir__, 'data/test-remote-sampler_sampling-rules-response-sample.json')
DATA_DIR_SAMPLING_TARGETS = File.join(__dir__, 'data/test-remote-sampler_sampling-targets-response-sample.json')
TEST_URL = 'localhost:2000'

describe OpenTelemetry::Sampler::XRay::AWSXRayRemoteSampler do
  it 'creates remote sampler with empty resource' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_RULES))
    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_TARGETS))

    sampler = OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.new(resource: OpenTelemetry::SDK::Resources::Resource.create)

    assert !sampler.instance_variable_get(:@rule_poller).nil?
    assert_equal(sampler.instance_variable_get(:@rule_polling_interval_millis), 300 * 1000)
    assert !sampler.instance_variable_get(:@sampling_client).nil?
    assert !sampler.instance_variable_get(:@rule_cache).nil?
    assert_match(/[a-f0-9]{24}/, sampler.instance_variable_get(:@client_id))
  end

  it 'creates remote sampler with populated resource' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_RULES))
    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_TARGETS))

    resource = OpenTelemetry::SDK::Resources::Resource.create(
      OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'test-service-name',
      OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'test-cloud-platform'
    )
    sampler = OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.new(resource: resource)

    assert !sampler.instance_variable_get(:@rule_poller).nil?
    assert_equal(sampler.instance_variable_get(:@rule_polling_interval_millis), 300 * 1000)
    assert !sampler.instance_variable_get(:@sampling_client).nil?
    assert !sampler.instance_variable_get(:@rule_cache).nil?
    assert_equal(sampler.instance_variable_get(:@rule_cache).instance_variable_get(:@sampler_resource), resource)
    assert_match(/[a-f0-9]{24}/, sampler.instance_variable_get(:@client_id))
  end

  it 'creates remote sampler with all fields populated' do
    stub_request(:post, 'abc.com/GetSamplingRules')
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_RULES))
    stub_request(:post, 'abc.com/SamplingTargets')
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_TARGETS))

    resource = OpenTelemetry::SDK::Resources::Resource.create(
      OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'test-service-name',
      OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'test-cloud-platform'
    )
    sampler = OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.new(
      resource: resource,
      endpoint: 'abc.com',
      polling_interval: 120
    )

    assert !sampler.instance_variable_get(:@rule_poller).nil?
    assert_equal(sampler.instance_variable_get(:@rule_polling_interval_millis), 120 * 1000)
    assert !sampler.instance_variable_get(:@sampling_client).nil?
    assert !sampler.instance_variable_get(:@rule_cache).nil?
    assert_equal(sampler.instance_variable_get(:@rule_cache).instance_variable_get(:@sampler_resource), resource)
    assert_equal(sampler.instance_variable_get(:@aws_proxy_endpoint), 'abc.com')
    assert_match(/[a-f0-9]{24}/, sampler.instance_variable_get(:@client_id))
  end

  it 'updates sampling rules and targets with pollers and should sample' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_RULES))
    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_TARGETS))

    resource = OpenTelemetry::SDK::Resources::Resource.create(
      OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'test-service-name',
      OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'test-cloud-platform'
    )
    rs = OpenTelemetry::Sampler::XRay::AWSXRayRemoteSampler.new(resource: resource)

    attributes = { 'abc' => '1234' }

    sleep(1.0)
    test_rule_applier = rs.instance_variable_get(:@root).instance_variable_get(:@root).instance_variable_get(:@rule_cache).instance_variable_get(:@rule_appliers)[0]
    assert_equal 'test', test_rule_applier.instance_variable_get(:@sampling_rule).instance_variable_get(:@rule_name)
    assert_equal OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
                 rs.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: attributes, links: []).instance_variable_get(:@decision)

    # TODO: Run more tests after updating Sampling Targets
  end

  it 'generates valid client id' do
    client_id = OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.generate_client_id
    assert_match(/[0-9a-z]{24}/, client_id)
  end

  it 'converts to string' do
    stub_request(:post, "#{TEST_URL}/GetSamplingRules")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_RULES))
    stub_request(:post, "#{TEST_URL}/SamplingTargets")
      .to_return(status: 200, body: File.read(DATA_DIR_SAMPLING_TARGETS))

    sampler = OpenTelemetry::Sampler::XRay::InternalAWSXRayRemoteSampler.new(resource: OpenTelemetry::SDK::Resources::Resource.create)
    expected_string = 'InternalAWSXRayRemoteSampler{aws_proxy_endpoint=127.0.0.1:2000, rule_polling_interval_millis=300000}'
    assert_equal(sampler.description, expected_string)
  end

  def create_spans(sampled_array, thread_id, span_attributes, remote_sampler, number_of_spans)
    sampled = 0
    number_of_spans.times do
      sampled += 1 if remote_sampler.should_sample?(parent_context: nil, trace_id: '3759e988bd862e3fe1be46a994272793', name: 'name', kind: OpenTelemetry::Trace::SpanKind::SERVER, attributes: span_attributes,
                                                    links: []).instance_variable_get(:@decision) != OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
    end
    sampled_array[thread_id] = sampled
  end

  # TODO: Run tests for Reservoir Sampling
end
