# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS::EKS do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS::EKS }
  # Constants for paths used in testing
  let(:token_path) { OpenTelemetry::Resource::Detector::AWS::EKS::TOKEN_PATH }
  let(:cert_path) { OpenTelemetry::Resource::Detector::AWS::EKS::CERT_PATH }
  let(:aws_auth_path) { OpenTelemetry::Resource::Detector::AWS::EKS::AWS_AUTH_PATH }
  let(:cluster_info_path) { OpenTelemetry::Resource::Detector::AWS::EKS::CLUSTER_INFO_PATH }

  describe '.detect' do
    before do
      # Set up file existence checks
      @token_path_exists = false
      @cert_path_exists = false

      # Store original environment variables
      @original_env = ENV.to_hash
      ENV.clear

      # Disable external network connections
      WebMock.disable_net_connect!
    end

    after do
      # Restore original environment
      ENV.replace(@original_env)

      # Re-enable network connections
      WebMock.allow_net_connect!
    end

    it 'returns empty resource when not running on K8s' do
      @token_path_exists = false
      @cert_path_exists = false

      File.stub :exist?, lambda { |path|
        if path == token_path
          @token_path_exists
        elsif path == cert_path
          @cert_path_exists
        else
          false
        end
      } do
        resource = detector.detect
        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(resource.attribute_enumerator.to_h).must_equal({})
      end
    end

    it 'returns empty resource when only token exists' do
      @token_path_exists = true
      @cert_path_exists = false

      File.stub :exist?, lambda { |path|
        if path == token_path
          @token_path_exists
        elsif path == cert_path
          @cert_path_exists
        else
          false
        end
      } do
        resource = detector.detect
        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(resource.attribute_enumerator.to_h).must_equal({})
      end
    end

    it 'returns empty resource when only cert exists' do
      @token_path_exists = false
      @cert_path_exists = true

      File.stub :exist?, lambda { |path|
        if path == token_path
          @token_path_exists
        elsif path == cert_path
          @cert_path_exists
        else
          false
        end
      } do
        resource = detector.detect
        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(resource.attribute_enumerator.to_h).must_equal({})
      end
    end

    describe 'when running on K8s' do
      # Mock values for EKS tests
      let(:mock_token) { 'k8s-token-value' }
      let(:mock_cred_value) { "Bearer #{mock_token}" }
      let(:mock_aws_auth_response) { '{"kind":"ConfigMap","data":{}}' }
      let(:mock_cluster_info_response) { '{"data":{"cluster.name":"my-eks-cluster"}}' }
      let(:mock_container_id) { '0123456789abcdef' * 4 }
      let(:mock_cluster_name) { 'my-eks-cluster' }

      before do
        @token_path_exists = true
        @cert_path_exists = true
      end

      let(:expected_resource_attributes) do
        {
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER => 'aws',
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'aws_eks',
          OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME => mock_cluster_name,
          OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID => mock_container_id
        }
      end

      it 'detects EKS resources' do
        # Mock file existence check
        File.stub :exist?, lambda { |path|
          if path == token_path
            @token_path_exists
          elsif path == cert_path
            @cert_path_exists
          else
            false
          end
        } do
          # Mock token file read
          File.stub :read, lambda { |path|
            raise "Unexpected file read: #{path}" unless path == token_path

            mock_token
          } do
            # Mock container ID retrieval
            detector.stub :container_id, mock_container_id do
              # Mock cluster name retrieval
              detector.stub :cluster_name, ->(_) { mock_cluster_name } do
                # Mock HTTP requests
                detector.stub :aws_http_request, lambda { |path, _auth|
                  if path == aws_auth_path
                    mock_aws_auth_response
                  elsif path == cluster_info_path
                    mock_cluster_info_response
                  else
                    raise "Unexpected HTTP request to #{path}"
                  end
                } do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Check attributes
                  _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
                  _(attributes).must_equal(expected_resource_attributes)
                end
              end
            end
          end
        end
      end

      it 'handles missing cluster name' do
        # Simplified test with direct stubs
        expected_attrs = {
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER => 'aws',
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'aws_eks',
          OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID => mock_container_id
        }

        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, mock_cred_value do
            detector.stub :eks?, true do
              detector.stub :cluster_name, ->(_) { '' } do
                detector.stub :container_id, mock_container_id do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Should still have container ID but no cluster name
                  _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
                  _(attributes).must_equal(expected_attrs)
                end
              end
            end
          end
        end
      end

      it 'handles missing container ID' do
        # Simplified test with direct stubs
        expected_attrs = {
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER => 'aws',
          OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'aws_eks',
          OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME => mock_cluster_name
        }

        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, mock_cred_value do
            detector.stub :eks?, true do
              detector.stub :cluster_name, ->(_) { mock_cluster_name } do
                detector.stub :container_id, '' do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Should still have cluster name but no container ID
                  _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
                  _(attributes).must_equal(expected_attrs)
                end
              end
            end
          end
        end
      end

      it 'returns empty resource when aws-auth check fails' do
        # Simplified test with direct stubs
        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, mock_cred_value do
            detector.stub :eks?, false do
              resource = detector.detect
              _(resource.attribute_enumerator.to_h).must_equal({})
            end
          end
        end
      end

      it 'returns empty resource when both cluster name and container ID are missing' do
        # Simplified test with direct stubs
        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, mock_cred_value do
            detector.stub :eks?, true do
              detector.stub :cluster_name, ->(_) { '' } do
                detector.stub :container_id, '' do
                  resource = detector.detect
                  _(resource.attribute_enumerator.to_h).must_equal({})
                end
              end
            end
          end
        end
      end
    end
  end
end
