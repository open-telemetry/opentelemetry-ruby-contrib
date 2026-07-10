# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::OS do
  let(:detector) { OpenTelemetry::Resource::Detector::OS }

  RESOURCE = OpenTelemetry::SemanticConventions::Resource

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }

    it 'returns a resource with os_type string' do
      _(detected_resource_attributes['os.type']).must_be_instance_of(String)
    end
  end
end
