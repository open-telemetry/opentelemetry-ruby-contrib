# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka/patches/async_producer'

describe OpenTelemetry::Instrumentation::RubyKafka::Patches::AsyncProducer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer('test-tracer') }
  let(:producer) { Kafka.new(['abc:123']).async_producer(delivery_threshold: 1000) }

  before(:each) do
    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '__otel_merge_options' do
    it 'injects context when options are not present' do
      tracer.in_span('wat') do
        opts = producer.__otel_merge_options!
        _(opts[:headers]['traceparent']).wont_be_nil
      end
    end

    it 'injects context when options are present but headers are not' do
      tracer.in_span('wat') do
        create_time = Time.now
        opts = producer.__otel_merge_options!(
          key: 'wat',
          partition: 1,
          partition_key: 'ok',
          create_time: create_time
        )
        _(opts[:headers]['traceparent']).wont_be_nil
        _(opts[:key]).must_equal('wat')
        _(opts[:partition]).must_equal(1)
        _(opts[:partition_key]).must_equal('ok')
        _(opts[:create_time]).must_equal(create_time)
      end
    end

    it 'injects context when headers are present' do
      tracer.in_span('wat') do
        create_time = Time.now
        opts = producer.__otel_merge_options!(
          key: 'wat',
          partition: 1,
          partition_key: 'ok',
          create_time: create_time,
          headers: { foo: :bar }
        )
        _(opts[:headers]['traceparent']).wont_be_nil
        _(opts[:headers][:foo]).must_equal(:bar)
        _(opts[:key]).must_equal('wat')
        _(opts[:partition]).must_equal(1)
        _(opts[:partition_key]).must_equal('ok')
        _(opts[:create_time]).must_equal(create_time)
      end
    end
  end
end unless ENV['OMIT_SERVICES']
