# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS }

  describe '.detect' do
    before do
      WebMock.disable_net_connect!
      # Ensure we stub any potential requests to EC2 metadata service
      # Simulate failed token request
      stub_request(:put, 'http://169.254.169.254/latest/api/token')
        .to_timeout

      # Simulate failed identity document request
      stub_request(:get, 'http://169.254.169.254/latest/dynamic/instance-identity/document')
        .with(headers: { 'Accept' => '*/*' })
        .to_return(status: 404, body: 'Not Found')
    end

    after do
      WebMock.allow_net_connect!
    end

    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end
  end
end
