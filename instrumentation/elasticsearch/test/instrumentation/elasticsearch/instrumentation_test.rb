# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/elasticsearch'

describe OpenTelemetry::Instrumentation::Elasticsearch do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Elasticsearch'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'present' do
    it 'when elasticsearch gem installed' do
      _(instrumentation.present?).must_equal(true)
    end

    it 'when Elasticsearch constant not present' do
      hide_const('Elastic')
      _(instrumentation.present?).must_equal(false)
    end
  end

  describe 'sanitize_field_names configured' do
    let(:config) { { sanitize_field_names: ['Auth*tion', 'abc*', '*xyz'] } }
    it 'converts to regexes' do
      instrumentation.install(config)
      _(instrumentation.config[:sanitize_field_names].collect(&:pattern)).must_equal(
        [
          /\AAuth.*tion\Z/i,
          /\Aabc.*\Z/i,
          /\A.*xyz\Z/i
        ]
      )
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      stub_const('::Elastic::Transport::VERSION', '7.17.7')
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end
end
