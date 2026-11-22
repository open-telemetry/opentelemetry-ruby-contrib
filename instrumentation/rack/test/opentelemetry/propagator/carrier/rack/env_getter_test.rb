# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::Carrier::Rack::EnvGetter do
  let(:getter) do
    OpenTelemetry::Propagator::Carrier::Rack::EnvGetter.new
  end

  let(:carrier) do
    {
      'HTTP_TRACEPARENT' => 'tp',
      'HTTP_TRACESTATE' => 'ts',
      'HTTP_X_SOURCE_ID' => '123',
      'rack.hijack?' => true
    }
  end

  describe '#get' do
    it 'reads key from carrier' do
      _(getter.get(carrier, 'traceparent')).must_equal('tp')
      _(getter.get(carrier, 'tracestate')).must_equal('ts')
      _(getter.get(carrier, 'x-source-id')).must_equal('123')
      _(getter.get(carrier, 'rack.hijack?')).must_equal(true)
    end

    it 'returns nil for non-existent key' do
      _(getter.get(carrier, 'not-here')).must_be_nil
    end
  end

  describe '#keys' do
    it 'returns carrier keys' do
      _(getter.keys(carrier)).must_equal(%w[traceparent tracestate x-source-id rack.hijack?])
    end

    it 'returns empty array for empty carrier' do
      _(getter.keys({})).must_equal([])
    end
  end

  describe '.env_getter' do
    it 'returns a memoized EnvGetter instance' do
      env_getter = OpenTelemetry::Propagator::Carrier::Rack.env_getter
      _(env_getter).must_be_instance_of(OpenTelemetry::Propagator::Carrier::Rack::EnvGetter)
      _(OpenTelemetry::Propagator::Carrier::Rack.env_getter).must_be_same_as(env_getter)
    end
  end
end
