# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::AutoDetector do
  before do
    WebMock.disable_net_connect!
    # Azure stub
    stub_request(:get, 'http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Host' => '169.254.169.254',
          'Metadata' => 'true',
          'User-Agent' => 'Ruby'
        }
      ).to_raise(SocketError)

    # Docker Containers stub
    stub_request(:get, 'http://unix/containers/json')
      .with(
        headers: {
          'Accept'=>'*/*',
          'Content-Type'=>'text/plain',
          'Host'=>'',
          'User-Agent'=>'Swipely/Docker-API 2.2.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    # Docker Images stub
    stub_request(:get, 'http://unix/images/json')
      .with(
        headers: {
          'Accept'=>'*/*',
          'Content-Type'=>'text/plain',
          'Host'=>'',
          'User-Agent'=>'Swipely/Docker-API 2.2.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    # GCP stub
    stub_request(:get, 'http://169.254.169.254/')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Metadata-Flavor' => 'Google',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '', headers: {})
  end

  after do
    WebMock.allow_net_connect!
  end

  let(:auto_detector) { OpenTelemetry::Resource::Detectors::AutoDetector }
  let(:detected_resource) { auto_detector.detect }
  let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
  let(:expected_resource_attributes) { {} }

  describe '.detect' do
    it 'returns detected resources' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end
  end
end
