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

    describe 'on linux' do
      # TODO
    end
    
    describe 'on macOS' do
      # TODO
    end
    
    describe 'on windows' do
      before do
        allow(detector).to receive(:target_os).and_return("mingw32")
        allow(Open3).to receive(:capture3).with("ver").and_return([
          "\nMicrosoft Windows [Version 10.0.26200.8037]\n",
          nil,
          nil,
        ])
      end

      it 'returns a resource with os.type = windows' do
        _(detected_resource_attributes['os.type']).must_equal("windows")
      end

      it 'returns a resource with os.name = Windows' do
        _(detected_resource_attributes['os.name']).must_equal("Windows")
      end

      it 'returns a resource with os.description (newlines deleted)' do
        _(detected_resource_attributes['os.description']).must_equal(
          "Microsoft Windows [Version 10.0.26200.8037]"
        )
      end
    end
  end
end
