# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Faraday do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('stable')

    exporter.reset
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Faraday'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'present' do
    it 'when faraday gem is installed' do
      assert_predicate instrumentation, :present?
    end

    it 'when Faraday is not defined' do
      hide_const('Faraday')
      refute_predicate instrumentation, :present?
    end
  end

  describe 'compatible' do
    it 'when faraday version meets minimum' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    it 'accepts empty arguments' do
      instrumentation.instance_variable_set(:@installed, false)
      _(instrumentation.install({})).must_equal true
    end
  end

  describe 'tracing' do
    let(:client) do
      Faraday.new('http://example.com') do |builder|
        builder.adapter(:test) do |stub|
          stub.get('/') { [200, {}, 'OK'] }
        end
      end
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      client.get('/')

      _(exporter.finished_spans.size).must_equal 1
    end
  end
end
