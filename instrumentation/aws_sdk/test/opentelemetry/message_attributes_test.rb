# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::AwsSdk do
  let(:instrumentation) { OpenTelemetry::Instrumentation::AwsSdk }

  describe 'MessageAttributeSetter' do
    it 'set when hash length is lower than 10' do
      key = 'foo'
      value = 'bar'
      metadata_attributes = {}
      instrumentation::MessageAttributeSetter.set(metadata_attributes, key, value)
      _(metadata_attributes[key]).must_equal(string_value: value, data_type: 'String')
    end

    it 'should keep existing attributes' do
      key = 'foo'
      value = 'bar'
      metadata_attributes = {
        'existingKey' => { string_value: 'existingValue', data_type: 'String' }
      }
      instrumentation::MessageAttributeSetter.set(metadata_attributes, key, value)
      _(metadata_attributes[key]).must_equal(string_value: value, data_type: 'String')
      _(metadata_attributes['existingKey'])
        .must_equal(string_value: 'existingValue', data_type: 'String')
    end

    it 'should not add if there are 10 or more existing attributes' do
      metadata_attributes = {
        'existingKey0' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey1' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey2' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey3' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey4' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey5' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey6' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey7' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey8' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey9' => { string_value: 'existingValue', data_type: 'String' }
      }
      instrumentation::MessageAttributeSetter.set(metadata_attributes, 'new10', 'value')
      _(metadata_attributes.keys)
        .must_equal(
          %w[
            existingKey0
            existingKey1
            existingKey2
            existingKey3
            existingKey4
            existingKey5
            existingKey6
            existingKey7
            existingKey8
            existingKey9
          ]
        )
    end
  end

  describe 'MessageAttributeGetter' do
    let(:getter) { instrumentation::MessageAttributeGetter }
    let(:carrier) do
      {
        'traceparent' => { data_type: 'String', string_value: 'tp' },
        'tracestate' => { data_type: 'String', string_value: 'ts' },
        'x-source-id' => { data_type: 'String', string_value: '123' }
      }
    end

    it 'reads key from carrier' do
      _(getter.get(carrier, 'traceparent')).must_equal('tp')
      _(getter.get(carrier, 'x-source-id')).must_equal('123')
    end

    it 'returns nil for non-existant key' do
      _(getter.get(carrier, 'not-here')).must_be_nil
    end
  end
end
