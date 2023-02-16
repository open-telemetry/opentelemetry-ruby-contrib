# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/deep_dup'
require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/sanitizer'

describe OpenTelemetry::Instrumentation::Elasticsearch::Patches::Sanitizer do
  let(:sanitizer) { OpenTelemetry::Instrumentation::Elasticsearch::Patches::Sanitizer }

  describe '#sanitize with default key patterns' do
    let(:obfuscate) { true }
    let(:obj) {
      {
        query: 'a query',
        password: 'top secret'
      }
    }

    it 'sanitizes default key patterns' do
      _(sanitizer.sanitize(obj, obfuscate)).must_equal(
        {
          query: 'a query',
          password: '?'
        }
      )
    end
  end

  describe '#sanitize with custom key patterns' do
    let(:obfuscate) { true }
    let(:key_patterns) { [/.*sensitive.*/] }

    let(:obj) {
      {
        query: 'a query',
        some_sensitive_field: 'sensitive data'
      }
    }

    it 'sanitizes custom key patterns' do
      _(sanitizer.sanitize(obj, obfuscate, key_patterns)).must_equal(
        {
          query: 'a query',
          some_sensitive_field: '?'
        }
      )
    end
  end

  describe '#sanitize with no matching key patterns' do
    let(:obfuscate) { true }
    let(:key_patterns) { [/.*sensitive.*/] }

    let(:obj) {
      {
        query: 'a query',
        a_normal_field: 'normal data'
      }
    }

    it 'does not sanitize fields' do
      _(sanitizer.sanitize(obj, obfuscate, key_patterns)).must_equal(
        {
          query: 'a query',
          a_normal_field: 'normal data'
        }
      )
    end
  end

  describe '#sanitize with obfuscate set to false' do
    let(:obfuscate) { false }
    let(:obj) {
      {
        query: 'a query',
        password: 'top secret'
      }
    }

    it 'does not obfuscate values' do
      _(sanitizer.sanitize(obj, obfuscate)).must_equal(
        {
          query: 'a query',
          password: 'top secret'
        }
      )
    end
  end
end
