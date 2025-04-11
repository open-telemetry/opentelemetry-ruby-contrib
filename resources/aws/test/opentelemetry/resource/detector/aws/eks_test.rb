# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS::EKS do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS::EKS }
  let(:token_path) { OpenTelemetry::Resource::Detector::AWS::EKS::TOKEN_PATH }
  let(:cert_path) { OpenTelemetry::Resource::Detector::AWS::EKS::CERT_PATH }
  let(:aws_auth_path) { OpenTelemetry::Resource::Detector::AWS::EKS::AWS_AUTH_PATH }
  let(:cluster_info_path) { OpenTelemetry::Resource::Detector::AWS::EKS::CLUSTER_INFO_PATH }

  describe '.detect' do
    before do
      # Set up file existence checks
      @token_path_exists = false
      @cert_path_exists = false
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
      let(:token) { 'k8s-token-value' }
      let(:cred_value) { "Bearer #{token}" }
      let(:aws_auth_response) { '{"kind":"ConfigMap","data":{}}' }
      let(:cluster_info_response) { '{"data":{"cluster.name":"my-eks-cluster"}}' }
      let(:container_id_val) { '0123456789abcdef' * 4 }
      let(:cluster_name_val) { 'my-eks-cluster' }

      before do
        @token_path_exists = true
        @cert_path_exists = true
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

            token
          } do
            # Mock container ID retrieval
            detector.stub :container_id, container_id_val do
              # Mock cluster name retrieval
              detector.stub :cluster_name, ->(_) { cluster_name_val } do
                # Mock HTTP requests
                detector.stub :aws_http_request, lambda { |_method, path, _auth|
                  if path == aws_auth_path
                    aws_auth_response
                  elsif path == cluster_info_path
                    cluster_info_response
                  else
                    raise "Unexpected HTTP request to #{path}"
                  end
                } do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Check attributes
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER]).must_equal('aws')
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM]).must_equal('aws_eks')
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME]).must_equal(cluster_name_val)
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID]).must_equal(container_id_val)
                end
              end
            end
          end
        end
      end

      it 'handles missing cluster name' do
        # Simplified test with direct stubs
        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, cred_value do
            detector.stub :eks?, true do
              detector.stub :cluster_name, ->(_) { '' } do
                detector.stub :container_id, container_id_val do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Should still have container ID but no cluster name
                  _(attributes).wont_include(OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME)
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID]).must_equal(container_id_val)
                end
              end
            end
          end
        end
      end

      it 'handles missing container ID' do
        # Simplified test with direct stubs
        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, cred_value do
            detector.stub :eks?, true do
              detector.stub :cluster_name, ->(_) { cluster_name_val } do
                detector.stub :container_id, '' do
                  resource = detector.detect
                  attributes = resource.attribute_enumerator.to_h

                  # Should still have cluster name but no container ID
                  _(attributes[OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME]).must_equal(cluster_name_val)
                  _(attributes).wont_include(OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID)
                end
              end
            end
          end
        end
      end

      it 'returns empty resource when aws-auth check fails' do
        # Simplified test with direct stubs
        detector.stub :k8s?, true do
          detector.stub :k8s_cred_value, cred_value do
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
          detector.stub :k8s_cred_value, cred_value do
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
