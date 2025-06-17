# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS }

  RESOURCE = OpenTelemetry::SemanticConventions::Resource

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

      # Clear environment variables for ECS and Lambda
      @original_env = ENV.to_hash
      ENV.delete('ECS_CONTAINER_METADATA_URI')
      ENV.delete('ECS_CONTAINER_METADATA_URI_V4')
      ENV.delete('AWS_LAMBDA_FUNCTION_NAME')
      ENV.delete('AWS_LAMBDA_FUNCTION_VERSION')
      ENV.delete('AWS_LAMBDA_LOG_STREAM_NAME')
    end

    after do
      WebMock.allow_net_connect!
      ENV.replace(@original_env)
    end

    def assert_detection_result(detectors)
      resource = detector.detect(detectors)
      attributes = resource.attribute_enumerator.to_h

      _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(attributes).must_equal({})
    end

    it 'returns an empty resource with no detectors' do
      assert_detection_result([])
    end

    it 'returns an empty resource when EC2 detection fails' do
      assert_detection_result([:ec2])
    end

    it 'returns an empty resource when ECS detection fails' do
      assert_detection_result([:ecs])
    end

    it 'returns an empty resource when Lambda detection fails' do
      assert_detection_result([:lambda])
    end

    it 'returns an empty resource when EKS detection fails' do
      assert_detection_result([:eks])
    end

    it 'returns an empty resource with unknown detector' do
      assert_detection_result([:unknown])
    end

    it 'returns an empty resource with multiple detectors when all fail' do
      assert_detection_result(%i[ec2 ecs eks lambda unknown])
    end

    describe 'with successful EC2 detection' do
      let(:token) { 'ec2-token-value' }
      let(:identity_document) do
        {
          'instanceId' => 'i-1234567890abcdef0',
          'instanceType' => 'm5.xlarge',
          'accountId' => '123456789012',
          'region' => 'us-west-2',
          'availabilityZone' => 'us-west-2b'
        }
      end
      let(:hostname) { 'ip-10-0-0-1.ec2.internal' }

      before do
        # Stub successful token request (IMDSv2)
        stub_request(:put, 'http://169.254.169.254/latest/api/token')
          .to_return(status: 200, body: token)

        # Stub successful identity document request
        stub_request(:get, 'http://169.254.169.254/latest/dynamic/instance-identity/document')
          .to_return(status: 200, body: identity_document.to_json)

        # Stub successful hostname request
        stub_request(:get, 'http://169.254.169.254/latest/meta-data/hostname')
          .with(headers: { 'X-aws-ec2-metadata-token' => token })
          .to_return(status: 200, body: hostname)
      end

      it 'detects EC2 resources when specified' do
        resource = detector.detect([:ec2])
        attributes = resource.attribute_enumerator.to_h

        _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
        _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_ec2')
        _(attributes[RESOURCE::CLOUD_ACCOUNT_ID]).must_equal('123456789012')
        _(attributes[RESOURCE::CLOUD_REGION]).must_equal('us-west-2')
        _(attributes[RESOURCE::CLOUD_AVAILABILITY_ZONE]).must_equal('us-west-2b')
        _(attributes[RESOURCE::HOST_ID]).must_equal('i-1234567890abcdef0')
        _(attributes[RESOURCE::HOST_TYPE]).must_equal('m5.xlarge')
        _(attributes[RESOURCE::HOST_NAME]).must_equal(hostname)
      end

      describe 'with succesefful ECS detection' do
        let(:metadata_uri_v4) { 'http://169.254.170.2/v4' }
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
          ENV['ECS_CONTAINER_METADATA_URI_V4'] = metadata_uri_v4

          # Stub container metadata endpoint
          stub_request(:get, metadata_uri_v4)
            .to_return(status: 200, body: container_metadata.to_json)

          # Stub task metadata endpoint
          stub_request(:get, "#{metadata_uri_v4}/task")
            .to_return(status: 200, body: task_metadata.to_json)
        end

        it 'detects ECS resources when specified' do
          # Properly stub the fetch_container_id method
          OpenTelemetry::Resource::Detector::AWS::ECS.stub :fetch_container_id, '0123456789abcdef' * 4 do
            # Also stub the hostname method
            Socket.stub :gethostname, 'test-container' do
              resource = detector.detect([:ecs])
              attributes = resource.attribute_enumerator.to_h

              _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
              _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_ecs')
            end
          end
        end

        it 'returns combined resources when multiple detectors are used' do
          # Stub the container ID and hostname methods
          OpenTelemetry::Resource::Detector::AWS::ECS.stub :fetch_container_id, '0123456789abcdef' * 4 do
            Socket.stub :gethostname, 'test-container' do
              # Mock EC2 detector to return a simple resource
              ec2_resource = OpenTelemetry::SDK::Resources::Resource.create({ 'ec2.instance.id' => 'i-1234567890abcdef0' })
              OpenTelemetry::Resource::Detector::AWS::EC2.stub :detect, ec2_resource do
                resource = detector.detect(%i[ec2 ecs])
                attributes = resource.attribute_enumerator.to_h

                # Should include attributes from both detectors
                _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
                _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_ecs')
                _(attributes['ec2.instance.id']).must_equal('i-1234567890abcdef0')
              end
            end
          end
        end

        describe 'with successful Lambda detection' do
          before do
            # Set Lambda environment variables
            ENV['AWS_LAMBDA_FUNCTION_NAME'] = 'my-function'
            ENV['AWS_LAMBDA_FUNCTION_VERSION'] = '$LATEST'
            ENV['AWS_LAMBDA_LOG_STREAM_NAME'] = '2025/01/01/[$LATEST]abcdef123456'
            ENV['AWS_REGION'] = 'us-east-1'
            ENV['AWS_LAMBDA_FUNCTION_MEMORY_SIZE'] = '512'
          end

          it 'detects Lambda resources when specified' do
            resource = detector.detect([:lambda])
            attributes = resource.attribute_enumerator.to_h

            _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
            _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_lambda')
            _(attributes[RESOURCE::CLOUD_REGION]).must_equal('us-east-1')
            _(attributes[RESOURCE::FAAS_NAME]).must_equal('my-function')
            _(attributes[RESOURCE::FAAS_VERSION]).must_equal('$LATEST')
            _(attributes[RESOURCE::FAAS_INSTANCE]).must_equal('2025/01/01/[$LATEST]abcdef123456')
            _(attributes[RESOURCE::FAAS_MAX_MEMORY]).must_equal(512)
          end

          it 'detects multiple resources when specified' do
            # Create a mock EC2 resource
            ec2_resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                            RESOURCE::HOST_ID => 'i-1234567890abcdef0'
                                                                          })

            # Stub EC2 detection to return the mock resource
            OpenTelemetry::Resource::Detector::AWS::EC2.stub :detect, ec2_resource do
              resource = detector.detect(%i[ec2 lambda])
              attributes = resource.attribute_enumerator.to_h

              # Should include attributes from both detectors
              _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
              _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_lambda')
              _(attributes[RESOURCE::FAAS_NAME]).must_equal('my-function')
              _(attributes[RESOURCE::HOST_ID]).must_equal('i-1234567890abcdef0')
            end
          end
        end

        describe 'with successful EKS detection' do
          let(:cluster_name) { 'my-eks-cluster' }
          let(:container_id) { '0123456789abcdef' * 4 }

          before do
            # No specific environment setup needed for EKS tests
            # They rely completely on stubbing
          end

          it 'detects EKS resources when specified' do
            # Create a mock EKS resource
            eks_resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                            RESOURCE::CLOUD_PROVIDER => 'aws',
                                                                            RESOURCE::CLOUD_PLATFORM => 'aws_eks',
                                                                            RESOURCE::K8S_CLUSTER_NAME => cluster_name,
                                                                            RESOURCE::CONTAINER_ID => container_id
                                                                          })

            # Stub EKS detection to return the mock resource
            OpenTelemetry::Resource::Detector::AWS::EKS.stub :detect, eks_resource do
              resource = detector.detect([:eks])
              attributes = resource.attribute_enumerator.to_h

              # Check EKS attributes
              _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
              _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_eks')
              _(attributes[RESOURCE::K8S_CLUSTER_NAME]).must_equal(cluster_name)
              _(attributes[RESOURCE::CONTAINER_ID]).must_equal(container_id)
            end
          end

          it 'combines EC2 and EKS resources when both are detected' do
            # Create a mock EC2 resource
            ec2_resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                            RESOURCE::HOST_ID => 'i-1234567890abcdef0',
                                                                            RESOURCE::HOST_TYPE => 'm5.xlarge'
                                                                          })

            # Create a mock EKS resource
            eks_resource = OpenTelemetry::SDK::Resources::Resource.create({
                                                                            RESOURCE::CLOUD_PROVIDER => 'aws',
                                                                            RESOURCE::CLOUD_PLATFORM => 'aws_eks',
                                                                            RESOURCE::K8S_CLUSTER_NAME => cluster_name,
                                                                            RESOURCE::CONTAINER_ID => container_id
                                                                          })

            # Stub both detectors
            OpenTelemetry::Resource::Detector::AWS::EC2.stub :detect, ec2_resource do
              OpenTelemetry::Resource::Detector::AWS::EKS.stub :detect, eks_resource do
                resource = detector.detect(%i[ec2 eks])
                attributes = resource.attribute_enumerator.to_h

                # Should include attributes from both detectors
                _(attributes[RESOURCE::CLOUD_PROVIDER]).must_equal('aws')
                _(attributes[RESOURCE::CLOUD_PLATFORM]).must_equal('aws_eks')
                _(attributes[RESOURCE::K8S_CLUSTER_NAME]).must_equal(cluster_name)
                _(attributes[RESOURCE::CONTAINER_ID]).must_equal(container_id)
                _(attributes[RESOURCE::HOST_ID]).must_equal('i-1234567890abcdef0')
                _(attributes[RESOURCE::HOST_TYPE]).must_equal('m5.xlarge')
              end
            end
          end
        end
      end
    end
  end
end
