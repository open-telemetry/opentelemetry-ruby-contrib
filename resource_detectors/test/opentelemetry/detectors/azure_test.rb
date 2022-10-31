# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::Azure do
  let(:detector) { OpenTelemetry::Resource::Detectors::Azure }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end

    describe 'when in an azure VM environment' do
      let(:project_id) { 'opentelemetry' }
      let(:azure_metadata) do
        {
          'subscriptionId' => project_id,
          'provider' => 'Microsoft.Compute',
          'location' => 'westeurope',
          'zone' => '2',
          'vmId' => '012345671234-abcd-1234-0123456789ab',
          'storageProfile' => { 'imageReference' => { 'id' => '/subscriptions/12345678-abcd-1234-abcd-0123456789ab/resourceGroups/AKS-Ubuntu/providers/Microsoft.Compute/galleries/AKSUbuntu/images/1804gen2containerd/versions/2022.06.22' } },
          'vmSize' => 'Standard_D2s_v3',
          'name' => 'opentelemetry'
        }
      end

      before do
        detector.stub(:azure_metadata, azure_metadata) { detected_resource }
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'azure',
          'cloud.account.id' => 'opentelemetry',
          'cloud.platform' => 'azure_vm',
          'cloud.region' => 'westeurope',
          'cloud.availability_zone' => '2',
          'host.id' => '012345671234-abcd-1234-0123456789ab',
          'host.image.id' => '/subscriptions/12345678-abcd-1234-abcd-0123456789ab/resourceGroups/AKS-Ubuntu/providers/Microsoft.Compute/galleries/AKSUbuntu/images/1804gen2containerd/versions/2022.06.22',
          'host.name' => 'opentelemetry',
          'host.type' => 'Standard_D2s_v3'
        }
      end

      it 'returns a resource with azure attributes' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end

      describe 'and a nil resource value is detected' do
        let(:project_id) { nil }

        it 'returns a resource without that attribute' do
          _(detected_resource_attributes.key?('cloud.account.id')).must_equal(false)
        end
      end

      describe 'and an empty string resource value is detected' do
        let(:project_id) { '' }

        it 'returns a resource without that attribute' do
          _(detected_resource_attributes.key?('cloud.account.id')).must_equal(false)
        end
      end
    end
  end
end
