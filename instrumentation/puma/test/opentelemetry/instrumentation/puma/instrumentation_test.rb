# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/puma'

describe OpenTelemetry::Instrumentation::Puma do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Puma::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Puma'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end

    it 'allows the plugin to be found' do
      instrumentation.install
      _(Puma::Plugins.find('opentelemetry')).must_equal(OpenTelemetry::Instrumentation::Puma::Plugin)
    end

    it 'prepends the patch to automatically load the plugin' do
      instrumentation.install
      puma_config = Puma::Configuration.new
      _(puma_config.plugins.instance_variable_get(:@instances).map(&:class))
        .must_include(OpenTelemetry::Instrumentation::Puma::Plugin)
    end
  end
end
