# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::AWS::Lambda do
  let(:detector) { OpenTelemetry::Resource::Detector::AWS::Lambda }

  describe '.detect' do
    before do
      # Store original environment variables
      @original_env = ENV.to_hash
      ENV.clear
    end

    after do
      # Restore original environment
      ENV.replace(@original_env)
    end

    it 'returns empty resource when not running on Lambda' do
      resource = detector.detect
      _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(resource.attribute_enumerator.to_h).must_equal({})
    end

    describe 'when running on Lambda' do
      before do
        # Set Lambda environment variables
        ENV['AWS_LAMBDA_FUNCTION_NAME'] = 'my-function'
        ENV['AWS_LAMBDA_FUNCTION_VERSION'] = '$LATEST'
        ENV['AWS_LAMBDA_LOG_STREAM_NAME'] = '2021/01/01/[$LATEST]abcdef123456'
        ENV['AWS_REGION'] = 'us-west-2'
        ENV['AWS_LAMBDA_FUNCTION_MEMORY_SIZE'] = '512'
      end

      it 'detects Lambda resources' do
        resource = detector.detect

        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        attributes = resource.attribute_enumerator.to_h

        # Check Lambda-specific attributes
        _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER]).must_equal('aws')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM]).must_equal('aws_lambda')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_REGION]).must_equal('us-west-2')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_NAME]).must_equal('my-function')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_VERSION]).must_equal('$LATEST')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_INSTANCE]).must_equal('2021/01/01/[$LATEST]abcdef123456')
        _(attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_MAX_MEMORY]).must_equal(512)
      end

      it 'handles missing memory size' do
        ENV.delete('AWS_LAMBDA_FUNCTION_MEMORY_SIZE')

        resource = detector.detect
        attributes = resource.attribute_enumerator.to_h

        _(attributes).wont_include(OpenTelemetry::SemanticConventions::Resource::FAAS_MAX_MEMORY)
      end
    end

    describe 'when partial Lambda environment is detected' do
      before do
        # Set only some Lambda environment variables
        ENV['AWS_LAMBDA_FUNCTION_NAME'] = 'my-function'
        # Missing AWS_LAMBDA_FUNCTION_VERSION
        ENV['AWS_LAMBDA_LOG_STREAM_NAME'] = '2021/01/01/[$LATEST]abcdef123456'
      end

      it 'returns empty resource' do
        resource = detector.detect
        _(resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(resource.attribute_enumerator.to_h).must_equal({})
      end
    end
  end
end
