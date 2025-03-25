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
      # You'll add stubs for AWS endpoints here
      stub_request(:put, "http://169.254.169.254/latest/api/token").
        with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host'=>'169.254.169.254',
            'User-Agent'=>'Ruby',
            'X-Aws-Ec2-Metadata-Token-Ttl-Seconds'=>'60'
          }).
          to_return(status: 404, body: "Not Found", headers: {})
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
