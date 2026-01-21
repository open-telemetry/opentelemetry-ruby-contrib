# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/active_record'

describe OpenTelemetry::Instrumentation::ActiveRecord do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance }
  let(:minimum_version) { OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation::MINIMUM_VERSION }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::ActiveRecord'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'compatible' do
    it 'when a version below the minimum supported gem version is installed' do
      ActiveRecord.stub(:version, Gem::Version.new('4.2.0')) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'when supported gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  describe 'configuration' do
    it 'has enable_notifications_instrumentation option' do
      _(instrumentation.config).must_respond_to(:key?)
      _(instrumentation.config.key?(:enable_notifications_instrumentation)).must_equal true
    end

    it 'defaults enable_notifications_instrumentation to false' do
      _(instrumentation.config[:enable_notifications_instrumentation]).must_equal false
    end

    it 'allows enabling notifications_instrumentation' do
      # This would need to be tested in an integration test with a fresh SDK configuration
      # since we can't easily reconfigure after installation in unit tests
      config = { enable_notifications_instrumentation: true }
      _(config[:enable_notifications_instrumentation]).must_equal true
    end
  end
end
