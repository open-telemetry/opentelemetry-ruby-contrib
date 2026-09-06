# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS::EC2 do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS::EC2 }
  let(:ec2_metadata_host) { '169.254.169.254' }
  let(:token_path) { '/latest/api/token' }
  let(:identity_document_path) { '/latest/dynamic/instance-identity/document' }
  let(:hostname_path) { '/latest/meta-data/hostname' }

  let(:mock_token) { 'mock-token-123456' }
  let(:mock_identity_document) do
    {
      accountId: '123456789012',
      architecture: 'x86_64',
      availabilityZone: 'mock-west-2a',
      billingProducts: nil,
      devpayProductCodes: nil,
      marketplaceProductCodes: nil,
      imageId: 'ami-0957cee1854021123',
      instanceId: 'i-1234ab56cd7e89f01',
      instanceType: 't2.micro-mock',
      kernelId: nil,
      pendingTime: '2021-07-13T21:53:41Z',
      privateIp: '172.12.34.567',
      ramdiskId: nil,
      region: 'mock-west-2',
      version: '2017-09-30'
    }
  end
  let(:mock_hostname) { 'ip-172-12-34-567.mock-west-2.compute.internal' }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }

    before do
      WebMock.disable_net_connect!
    end

    after do
      WebMock.allow_net_connect!
    end

    describe 'when running on EC2 with successful responses' do
      before do
        # Stub token request
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .with(headers: { 'X-aws-ec2-metadata-token-ttl-seconds' => '60' })
          .to_return(status: 200, body: mock_token)

        # Stub identity document request
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_return(status: 200, body: mock_identity_document.to_json)

        # Stub hostname request
        stub_request(:get, "http://#{ec2_metadata_host}#{hostname_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_return(status: 200, body: mock_hostname)
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'aws',
          'cloud.platform' => 'aws_ec2',
          'cloud.account.id' => '123456789012',
          'cloud.region' => 'mock-west-2',
          'cloud.availability_zone' => 'mock-west-2a',
          'host.id' => 'i-1234ab56cd7e89f01',
          'host.type' => 't2.micro-mock',
          'host.name' => 'ip-172-12-34-567.mock-west-2.compute.internal'
        }
      end

      it 'returns a resource with EC2 attributes' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when token request fails' do
      before do
        # Simulate connection timeout for token request (IMDSv2)
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .to_timeout

        # Stub IMDSv1 fallback request for identity document (without token)
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: mock_identity_document.to_json)

        # Stub IMDSv1 fallback request for hostname (without token)
        stub_request(:get, "http://#{ec2_metadata_host}#{hostname_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: mock_hostname)
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'aws',
          'cloud.platform' => 'aws_ec2',
          'cloud.account.id' => '123456789012',
          'cloud.region' => 'mock-west-2',
          'cloud.availability_zone' => 'mock-west-2a',
          'host.id' => 'i-1234ab56cd7e89f01',
          'host.type' => 't2.micro-mock',
          'host.name' => 'ip-172-12-34-567.mock-west-2.compute.internal'
        }
      end

      it 'falls back to IMDSv1 and returns a resource with EC2 attributes' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when token request returns error code' do
      before do
        # Simulate 403 error for token request
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .to_return(status: 403, body: 'Forbidden')

        # Stub IMDSv1 fallback request for identity document (without token)
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: mock_identity_document.to_json)

        # Stub IMDSv1 fallback request for hostname (without token)
        stub_request(:get, "http://#{ec2_metadata_host}#{hostname_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: mock_hostname)
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'aws',
          'cloud.platform' => 'aws_ec2',
          'cloud.account.id' => '123456789012',
          'cloud.region' => 'mock-west-2',
          'cloud.availability_zone' => 'mock-west-2a',
          'host.id' => 'i-1234ab56cd7e89f01',
          'host.type' => 't2.micro-mock',
          'host.name' => 'ip-172-12-34-567.mock-west-2.compute.internal'
        }
      end

      it 'falls back to IMDSv1 and returns a resource with EC2 attributes' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when identity document request fails' do
      before do
        # Successful token request
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .with(headers: { 'X-aws-ec2-metadata-token-ttl-seconds' => '60' })
          .to_return(status: 200, body: mock_token)

        # Identity document request with token fails (IMDSv2)
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_return(status: 500, body: 'Internal Server Error')

        # Identity document request without token also fails (IMDSv1 fallback)
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns an empty resource' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal({})
      end
    end

    describe 'when identity document is not valid JSON' do
      before do
        # Successful token request
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .with(headers: { 'X-aws-ec2-metadata-token-ttl-seconds' => '60' })
          .to_return(status: 200, body: mock_token)

        # Identity document is invalid JSON (IMDSv2)
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_return(status: 200, body: '{not valid json')

        # Identity document is also invalid JSON when accessed via IMDSv1
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: '{not valid json')
      end

      it 'returns an empty resource' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal({})
      end
    end

    describe 'when hostname request fails' do
      before do
        # Successful token request
        stub_request(:put, "http://#{ec2_metadata_host}#{token_path}")
          .with(headers: { 'X-aws-ec2-metadata-token-ttl-seconds' => '60' })
          .to_return(status: 200, body: mock_token)

        # Successful identity document request with IMDSv2
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_return(status: 200, body: mock_identity_document.to_json)

        # Also stub the IMDSv1 fallback for identity document (without token)
        # This ensures we don't get unexpected requests even if code paths change
        stub_request(:get, "http://#{ec2_metadata_host}#{identity_document_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_return(status: 200, body: mock_identity_document.to_json)

        # Hostname request times out
        stub_request(:get, "http://#{ec2_metadata_host}#{hostname_path}")
          .with(headers: { 'X-aws-ec2-metadata-token' => mock_token })
          .to_timeout

        # Also stub the IMDSv1 fallback for hostname (without token)
        stub_request(:get, "http://#{ec2_metadata_host}#{hostname_path}")
          .with(headers: { 'Accept' => '*/*' })
          .to_timeout
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'aws',
          'cloud.platform' => 'aws_ec2',
          'cloud.account.id' => '123456789012',
          'cloud.region' => 'mock-west-2',
          'cloud.availability_zone' => 'mock-west-2a',
          'host.id' => 'i-1234ab56cd7e89f01',
          'host.type' => 't2.micro-mock'
          # host.name is missing because the request failed
        }
      end

      it 'returns a resource without the hostname' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end
  end
end
