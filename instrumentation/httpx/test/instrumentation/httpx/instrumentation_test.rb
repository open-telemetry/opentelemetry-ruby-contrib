# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/httpx'

describe OpenTelemetry::Instrumentation::HTTPX do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTPX::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::HTTPX'
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

  describe 'compatible' do
    it 'returns true when HTTPX version is >= 1.6.0' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'present' do
    it 'returns truthy when HTTPX is defined' do
      assert instrumentation.present?
    end
  end

  describe '#determine_semconv' do
    after do
      ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
    end

    it 'returns stable by default' do
      ENV.delete('OTEL_SEMCONV_STABILITY_OPT_IN')
      _(instrumentation.determine_semconv).must_equal 'stable'
    end

    it 'returns old when OTEL_SEMCONV_STABILITY_OPT_IN is old' do
      ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'old'
      _(instrumentation.determine_semconv).must_equal 'old'
    end

    it 'returns dup when OTEL_SEMCONV_STABILITY_OPT_IN is http/dup' do
      ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http/dup'
      _(instrumentation.determine_semconv).must_equal 'dup'
    end

    it 'prioritizes http/dup over old' do
      ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'http/dup,old'
      _(instrumentation.determine_semconv).must_equal 'dup'
    end
  end

  describe '#emit_old_semconv_deprecation_warning' do
    it 'emits a deprecation warning' do
      OpenTelemetry.stub(:logger, Logger.new(StringIO.new)) do
        expect(OpenTelemetry.logger).to receive(:warn).with(/deprecated/)
        instrumentation.emit_old_semconv_deprecation_warning('old')
      end
    end
  end
end
