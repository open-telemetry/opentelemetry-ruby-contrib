# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/http'

describe OpenTelemetry::Instrumentation::HTTP do
  before { skip unless ENV['BUNDLE_GEMFILE'].include?('old') }

  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::HTTP'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'present' do
    it 'when http gem installed' do
      _(instrumentation.present?).must_equal(true)
    end

    it 'when HTTP constant not present' do
      hide_const('HTTP')
      _(instrumentation.present?).must_equal(false)
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end

  describe 'determine_semconv' do
    it 'returns "dup" when OTEL_SEMCONV_STABILITY_OPT_IN includes other configs' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => 'http/dup, database') do
        _(instrumentation.determine_semconv).must_equal('dup')
      end
    end

    it 'returns "dup" when OTEL_SEMCONV_STABILITY_OPT_IN includes both http/dup and http' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => 'http/dup, http') do
        _(instrumentation.determine_semconv).must_equal('dup')
      end
    end

    it 'returns "stable" when OTEL_SEMCONV_STABILITY_OPT_IN is http' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => 'http') do
        _(instrumentation.determine_semconv).must_equal('stable')
      end
    end

    it 'returns "old" when OTEL_SEMCONV_STABILITY_OPT_IN is empty' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => '') do
        _(instrumentation.determine_semconv).must_equal('old')
      end
    end
  end
end
