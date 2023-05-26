# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/shoryuken'

describe OpenTelemetry::Instrumentation::Shoryuken::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Shoryuken::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Shoryuken'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      stub_const('::Shoryuken::VERSION', '5.2.3')
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end
end
