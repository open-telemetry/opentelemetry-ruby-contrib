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
        gcp_env_mock = instance_double(Google::Cloud::Env)

        allow(gcp_env_mock).to receive(:compute_engine?).and_return(true)
        allow(gcp_env_mock).to receive(:project_id).and_return(project_id)
        allow(gcp_env_mock).to receive(:instance_attribute).with('cluster-location').and_return('us-central1')
        allow(gcp_env_mock).to receive(:instance_zone).and_return('us-central1-a')
        allow(gcp_env_mock).to receive(:lookup_metadata).with('instance', 'id').and_return('opentelemetry-test')
        allow(gcp_env_mock).to receive(:lookup_metadata).with('instance', 'hostname').and_return('opentelemetry-node-1')
        allow(gcp_env_mock).to receive(:instance_attribute).with('cluster-name').and_return('opentelemetry-cluster')
        allow(gcp_env_mock).to receive(:kubernetes_engine?).and_return(true)
        allow(gcp_env_mock).to receive(:kubernetes_engine_namespace_id).and_return('default')
        allow(gcp_env_mock).to receive(:knative?).and_return(true)
        allow(gcp_env_mock).to receive(:project_id).and_return(project_id)
        allow(gcp_env_mock).to receive(:knative_service_id).and_return('test-google-cloud-function')
        allow(gcp_env_mock).to receive(:knative_service_revision).and_return('2')
        allow(gcp_env_mock).to receive(:instance_zone).and_return('us-central1-a')

        allow(Socket).to receive(:gethostname).and_return('opentelemetry-test')
        old_hostname = ENV.fetch('HOSTNAME', nil)
        ENV['HOSTNAME'] = 'opentelemetry-host-name-1'
        begin
          allow(Google::Cloud::Env).to receive(:new).and_return(gcp_env_mock)
          detected_resource
        ensure
          ENV['HOSTNAME'] = old_hostname
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
