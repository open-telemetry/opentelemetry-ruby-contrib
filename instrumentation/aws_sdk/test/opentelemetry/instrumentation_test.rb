# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::AwsSdk do
  let(:instrumentation) { OpenTelemetry::Instrumentation::AwsSdk::Instrumentation.instance }
  let(:minimum_version) { OpenTelemetry::Instrumentation::AwsSdk::Instrumentation::MINIMUM_VERSION }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::AwsSdk'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#compatible' do
    it 'returns false for unsupported gem versions' do
      Gem.stub(:loaded_specs, { 'aws-sdk-core' => nil, 'aws-sdk' => nil }) do
        hide_const('::Aws::CORE_GEM_VERSION')
        _(instrumentation.compatible?).must_equal false
      end

      Gem.stub(
        :loaded_specs,
        {
          'aws-sdk-core' => nil,
          'aws-sdk' => Gem::Specification.new { |s| s.version = '1.0.0' }
        }
      ) do
        hide_const('::Aws::CORE_GEM_VERSION')
        _(instrumentation.compatible?).must_equal false
      end

      Gem.stub(
        :loaded_specs,
        {
          'aws-sdk-core' => Gem::Specification.new { |s| s.version = '1.0.0' },
          'aws-sdk' => nil
        }
      ) do
        hide_const('::Aws::CORE_GEM_VERSION')
        _(instrumentation.compatible?).must_equal false
      end

      Gem.stub(:loaded_specs, { 'aws-sdk-core' => nil, 'aws-sdk' => nil }) do
        stub_const('::Aws::CORE_GEM_VERSION', '1.9.9')
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'returns true for supported gem versions' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  it 'with default options' do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install
    _(instrumentation.config[:inject_messaging_context]).must_equal(false)
    _(instrumentation.config[:enable_internal_instrumentation]).must_equal(false)
    _(instrumentation.config[:suppress_internal_instrumentation]).must_equal(false)
  end

  it 'honors deprecated config, :suppress_internal_instrumentation' do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(suppress_internal_instrumentation: true)
    _(instrumentation.config[:enable_internal_instrumentation]).must_equal(false)
  end
end
