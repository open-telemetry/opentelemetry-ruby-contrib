# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/resource/detector/aws/ec2'

module OpenTelemetry
  module Resource
    module Detector
      # AWS contains detect class method for determining AWS environment resource attributes
      module AWS
        extend self

        def detect
          # This will be a composite of all the AWS platform detectors
          ec2_resource = EC2.detect

          # For now, return the EC2 resource directly
          # In the future, we'll implement detection for EC2, ECS, EKS, etc.
          return ec2_resource
        end
      end
    end
  end
end
