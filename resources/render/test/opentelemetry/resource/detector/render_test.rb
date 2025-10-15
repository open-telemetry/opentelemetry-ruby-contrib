# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::Render do
  let(:detector) { OpenTelemetry::Resource::Detector::Render }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    describe 'when NOT in a Render environment' do
      it 'returns an empty resource' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when in a Render environment' do
      let(:render_environment_variables) do
        {
          'RENDER_EXTERNAL_HOSTNAME' => 'example.onrender.com',
          'RENDER_GIT_REPO_SLUG' => 'foo/bar',
          'RENDER' => 'true',
          'RENDER_SERVICE_ID' => 'srv-1234567890',
          'RENDER_CPU_COUNT' => '2',
          'RENDER_EXTERNAL_URL' => 'https://example.onrender.com',
          'RENDER_SERVICE_TYPE' => 'web',
          'RENDER_GIT_BRANCH' => 'main',
          'RENDER_INSTANCE_ID' => 'srv-1234567890-abcd1234',
          'RENDER_GIT_COMMIT' => 'd94b5f7ec7c6d7602c78a5e9b8a5b8c94d093eda',
          'RENDER_SERVICE_NAME' => 'example-22zn',
          'RENDER_DISCOVERY_SERVICE' => 'example-discovery',
          'PORT' => '10000'
        }
      end

      let(:expected_resource_attributes) do
        {
          'cloud.provider' => 'render',
          'render.is_pull_request' => 'false',
          'render.git.branch' => 'main',
          'render.git.repo_slug' => 'foo/bar',
          'service.instance.id' => 'srv-1234567890-abcd1234',
          'service.name' => 'example-22zn',
          'service.version' => 'd94b5f7ec7c6d7602c78a5e9b8a5b8c94d093eda'
        }
      end

      it 'returns a resource with container id for cgroup v1' do
        OpenTelemetry::TestHelpers.with_env(render_environment_variables) do
          _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
          _(detected_resource_attributes).must_equal(expected_resource_attributes)
        end
      end

      describe 'and a nil resource value is detected' do
        let(:render_environment_variables) do
          {
            'RENDER' => 'true'
          }
        end

        it 'returns a resource without that attribute' do
          OpenTelemetry::TestHelpers.with_env(render_environment_variables) do
            _(detected_resource_attributes.key?('service.id')).must_equal(false)
          end
        end

        it 'returns the default service name' do
          OpenTelemetry::TestHelpers.with_env(render_environment_variables) do
            _(detected_resource_attributes['service.name']).must_equal('unknown_service')
          end
        end
      end

      describe 'and an empty string resource value is detected' do
        let(:render_environment_variables) do
          {
            'RENDER' => 'true',
            'RENDER_SERVICE_ID' => ''
          }
        end

        it 'returns a resource without that attribute' do
          OpenTelemetry::TestHelpers.with_env(render_environment_variables) do
            _(detected_resource_attributes.key?('service.id')).must_equal(false)
          end
        end
      end
    end
  end
end
