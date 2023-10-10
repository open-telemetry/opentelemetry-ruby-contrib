# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::GoogleCloudPlatform do
  let(:detector) { OpenTelemetry::Resource::Detector::GoogleCloudPlatform }

  describe '.detect' do
    before do
      WebMock.disable_net_connect!
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

    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_attributes).must_equal(expected_resource_attributes)
    end

    describe 'when in a gcp environment' do
      let(:project_id) { 'opentelemetry' }

      before do
        gcp_env_mock = Minitest::Mock.new
        gcp_env_mock.expect(:compute_engine?, true)
        gcp_env_mock.expect(:project_id, project_id)
        gcp_env_mock.expect(:instance_attribute, 'us-central1', %w[cluster-location])
        gcp_env_mock.expect(:instance_zone, 'us-central1-a')
        gcp_env_mock.expect(:lookup_metadata, 'opentelemetry-test', %w[instance id])
        gcp_env_mock.expect(:lookup_metadata, 'opentelemetry-node-1', %w[instance hostname])
        gcp_env_mock.expect(:instance_attribute, 'opentelemetry-cluster', %w[cluster-name])
        gcp_env_mock.expect(:kubernetes_engine?, true)
        gcp_env_mock.expect(:kubernetes_engine_namespace_id, 'default')
        gcp_env_mock.expect(:knative?, true)
        gcp_env_mock.expect(:project_id, project_id)
        gcp_env_mock.expect(:knative_service_id, 'test-google-cloud-function')
        gcp_env_mock.expect(:knative_service_revision, '2')
        gcp_env_mock.expect(:instance_zone, 'us-central1-a')

        Socket.stub(:gethostname, 'opentelemetry-test') do
          old_hostname = ENV.fetch('HOSTNAME', nil)
          ENV['HOSTNAME'] = 'opentelemetry-host-name-1'
          begin
            Google::Cloud::Env.stub(:new, gcp_env_mock) { detected_resource }
          ensure
            ENV['HOSTNAME'] = old_hostname
          end
        end
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'gcp',
          'cloud.account.id' => 'opentelemetry',
          'cloud.region' => 'us-central1',
          'cloud.availability_zone' => 'us-central1-a',
          'host.id' => 'opentelemetry-test',
          'host.name' => 'opentelemetry-host-name-1',
          'k8s.cluster.name' => 'opentelemetry-cluster',
          'k8s.namespace.name' => 'default',
          'k8s.pod.name' => 'opentelemetry-host-name-1',
          'k8s.node.name' => 'opentelemetry-node-1',
          'faas.name' => 'test-google-cloud-function',
          'faas.version' => '2'
        }
      end

      it 'returns a resource with gcp attributes' do
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
