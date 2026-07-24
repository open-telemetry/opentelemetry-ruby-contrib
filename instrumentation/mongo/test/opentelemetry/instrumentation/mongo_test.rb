# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require_relative '../../test_helper'

describe OpenTelemetry::Instrumentation::Mongo do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Mongo::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    # Ensure default semconv mode (old - no env var)
    ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
    # Clear previous instrumentation state and subscribers between test runs
    instrumentation.instance_variable_set(:@installed, false)
    Mongo::Monitoring::Global.subscribers['Command'] = [] if defined?(Mongo::Monitoring::Global)
    instrumentation.install
    exporter.reset
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
    ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
  end

  describe 'present' do
    it 'when mongo gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when mongo gem not installed' do
      hide_const('Mongo')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      stub_const('::Mongo::VERSION', '2.4.3')
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'install' do
    it 'installs the subscriber' do
      # Subscriber class depends on OTEL_SEMCONV_STABILITY_OPT_IN environment variable
      stability_opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', '')
      values = stability_opt_in.split(',').map(&:strip)

      klass = if values.include?('database/dup')
                OpenTelemetry::Instrumentation::Mongo::Subscribers::Dup::Subscriber
              elsif values.include?('database')
                OpenTelemetry::Instrumentation::Mongo::Subscribers::Stable::Subscriber
              else
                OpenTelemetry::Instrumentation::Mongo::Subscribers::Old::Subscriber
              end
      subscribers = Mongo::Monitoring::Global.subscribers['Command']

      _(subscribers.size).must_equal 1
      _(subscribers.first).must_be_kind_of klass
    end
  end

  describe 'tracing' do
    before do
      TestHelper.setup_mongo
    end

    after do
      TestHelper.teardown_mongo
    end

    it 'before job' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after job' do
      client = TestHelper.client

      client['people'].insert_one(name: 'Steve', hobbies: ['hiking'])
      _(exporter.finished_spans.size).must_equal 1

      client['people'].find(name: 'Steve').first
      _(exporter.finished_spans.size).must_equal 2
    end
  end unless ENV['OMIT_SERVICES']
end
