# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/grape'

describe OpenTelemetry::Instrumentation::Grape do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Grape::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Grape'
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
  end

  describe '#compatible' do
    it 'returns false for older gem versions' do
      stub_const('::Grape::VERSION', '0.12.0')
      _(instrumentation.compatible?).must_equal false
    end

    it 'returns true for newer gem versions' do
      stub_const('::Grape::VERSION', '1.7.0')
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#config' do
    before do
      # Simulate a fresh install
      uninstall_and_cleanup
      instrumentation.install(config)
    end

    describe 'when configs are empty' do
      let(:config) { {} }

      it 'is installed with default settings when configs are empty' do
        _(instrumentation).must_be :installed?
        _(instrumentation.config[:ignored_events]).must_be_empty
      end
    end

    describe 'when configs are not empty' do
      let(:config) { { ignored_events: [:endpoint_render] } }

      it 'is installed with the specified configs' do
        _(instrumentation).must_be :installed?
        _(instrumentation.config[:ignored_events]).must_equal [:endpoint_render]
      end
    end
  end
end
