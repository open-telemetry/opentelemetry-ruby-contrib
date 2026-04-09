# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/net/http/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/net/http/patches/stable/instrumentation'

describe OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance }

  describe 'semantic convention selection' do
    after do
      ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
    end

    it 'defaults to stable when no env set' do
      ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
      result = instrumentation.send(:determine_semconv)
      _(result).must_equal 'stable'
    end

    it 'selects dup and warns when http/dup set' do
      ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http/dup'

      expect(OpenTelemetry.logger).to receive(:warn)
      result = instrumentation.send(:determine_semconv)
      _(result).must_equal 'dup'
    end

    it 'selects old and warns when old set' do
      ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'old'

      expect(OpenTelemetry.logger).to receive(:warn)
      result = instrumentation.send(:determine_semconv)
      _(result).must_equal 'old'
    end
  end

  describe 'split_path_and_query helper' do
    it 'splits path and query when query present' do
      dummy = Class.new do
        include OpenTelemetry::Instrumentation::Net::HTTP::Patches::Stable::Instrumentation
      end.new

      path, query = dummy.send(:split_path_and_query, '/foo/bar?x=1&y=2')
      _(path).must_equal '/foo/bar'
      _(query).must_equal 'x=1&y=2'
    end

    it 'returns nil query when absent' do
      dummy = Class.new do
        include OpenTelemetry::Instrumentation::Net::HTTP::Patches::Stable::Instrumentation
      end.new

      path, query = dummy.send(:split_path_and_query, '/foo')
      _(path).must_equal '/foo'
      _(query).must_be_nil
    end
  end
end
