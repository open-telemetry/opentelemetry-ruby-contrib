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
    let(:obj) do
      {
        query: 'a query',
        password: 'top secret'
      }
    end

    it 'sanitizes default key patterns' do
      _(sanitizer.sanitize(obj)).must_equal(
        {
          query: 'a query',
          password: '?'
        }
      )
    end
  end

  describe '#sanitize with custom key patterns' do
    let(:key_patterns) { [/.*sensitive.*/] }

    let(:obj) do
      {
        query: 'a query',
        some_sensitive_field: 'sensitive data'
      }
    end

    it 'sanitizes custom key patterns' do
      _(sanitizer.sanitize(obj, key_patterns)).must_equal(
        {
          query: 'a query',
          some_sensitive_field: '?'
        }
      )
    end
  end

  describe '#sanitize with no matching key patterns' do
    let(:key_patterns) { [/.*sensitive.*/] }

    let(:obj) do
      {
        query: 'a query',
        a_normal_field: 'normal data'
      }
    end

    it 'does not sanitize fields' do
      _(sanitizer.sanitize(obj, key_patterns)).must_equal(
        {
          query: 'a query',
          a_normal_field: 'normal data'
        }
      )
    end
  end
end
