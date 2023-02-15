# # frozen_string_literal: true
#
# # Copyright The OpenTelemetry Authors
# #
# # SPDX-License-Identifier: Apache-2.0

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

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end
end
