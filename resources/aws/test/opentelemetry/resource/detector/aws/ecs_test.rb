# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS::ECS do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS::ECS }

  describe '.detect' do
    let(:metadata_uri) { 'http://169.254.170.2/v3' }
    let(:metadata_uri_v4) { 'http://169.254.170.2/v4' }
    let(:hostname) { 'test-container' }

    let(:container_metadata) do
      {
        'ContainerARN' => 'arn:aws:ecs:us-west-2:123456789012:container/container-id',
        'LogDriver' => 'awslogs',
        'LogOptions' => {
          'awslogs-region' => 'us-west-2',
          'awslogs-group' => 'my-log-group',
          'awslogs-stream' => 'my-log-stream'
        }
      }
    end

    let(:task_metadata) do
      {
        'Cluster' => 'my-cluster',
        'TaskARN' => 'arn:aws:ecs:us-west-2:123456789012:task/task-id',
        'Family' => 'my-task-family',
        'Revision' => '1',
        'LaunchType' => 'FARGATE'
      }
    end

    before do
      # Stub environment variables, hostname and File operations
      @original_env = ENV.to_hash
      ENV.clear

      # Initialize WebMock
      WebMock.disable_net_connect!
    end

    after do
      # Restore original environment
      ENV.replace(@original_env)
      WebMock.allow_net_connect!
    end

    it 'returns empty resource when not running on ECS' do
      resource = detector.detect
      _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(resource.attribute_enumerator.to_h).must_equal({})
    end

    describe 'when running on ECS with metadata endpoint v4' do
      before do
        ENV['ECS_CONTAINER_METADATA_URI_V4'] = metadata_uri_v4

        # Stub container metadata endpoint
        stub_request(:get, metadata_uri_v4)
          .to_return(status: 200, body: container_metadata.to_json)

        # Stub task metadata endpoint
        stub_request(:get, "#{metadata_uri_v4}/task")
          .to_return(status: 200, body: task_metadata.to_json)
      end

      it 'detects ECS resources' do
        # Stub the fetch_container_id method directly rather than trying to stub File
        detector.stub :fetch_container_id, '0123456789abcdef' * 4 do
          Socket.stub :gethostname, hostname do
            resource = detector.detect

            _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            attributes = resource.attribute_enumerator.to_h

            # Check basic attributes
            _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER]).must_equal('aws')
            _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM]).must_equal('aws_ecs')
            _(attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_NAME]).must_equal(hostname)
            _(attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID]).must_equal('0123456789abcdef' * 4)

            # Check ECS-specific attributes
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_CONTAINER_ARN]).must_equal(container_metadata['ContainerARN'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_CLUSTER_ARN]).must_equal('arn:aws:ecs:us-west-2:123456789012:cluster/my-cluster')
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_LAUNCHTYPE]).must_equal('fargate')
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_TASK_ARN]).must_equal(task_metadata['TaskARN'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_TASK_FAMILY]).must_equal(task_metadata['Family'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_ECS_TASK_REVISION]).must_equal(task_metadata['Revision'])

            # Check log attributes
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_LOG_GROUP_NAMES]).must_equal(['my-log-group'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_LOG_GROUP_ARNS]).must_equal(['arn:aws:logs:us-west-2:123456789012:log-group:my-log-group'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_LOG_STREAM_NAMES]).must_equal(['my-log-stream'])
            _(attributes[OpenTelemetry::SemanticConventions::Resource::AWS_LOG_STREAM_ARNS]).must_equal(['arn:aws:logs:us-west-2:123456789012:log-group:my-log-group:log-stream:my-log-stream'])
          end
        end
      end
    end

    describe 'when metadata endpoint fails' do
      before do
        ENV['ECS_CONTAINER_METADATA_URI_V4'] = metadata_uri_v4

        # Stub metadata endpoint to fail
        stub_request(:get, metadata_uri_v4)
          .to_return(status: 500, body: 'Server Error')
      end

      it 'returns empty resource on error' do
        resource = detector.detect
        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(resource.attribute_enumerator.to_h).must_equal({})
      end
    end
  end
end
