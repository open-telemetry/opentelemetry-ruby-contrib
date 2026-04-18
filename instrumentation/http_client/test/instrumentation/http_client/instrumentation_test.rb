# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/http_client'

describe OpenTelemetry::Instrumentation::HttpClient do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HttpClient::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::HttpClient'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'determine_semconv' do
    it 'returns "dup" when OTEL_SEMCONV_STABILITY_OPT_IN includes http/dup' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => 'http/dup') do
        _(instrumentation.send(:determine_semconv)).must_equal('dup')
      end
    end

    it 'returns "old" when OTEL_SEMCONV_STABILITY_OPT_IN is old' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => 'old') do
        _(instrumentation.send(:determine_semconv)).must_equal('old')
      end
    end

    it 'returns "stable" when OTEL_SEMCONV_STABILITY_OPT_IN is empty' do
      OpenTelemetry::TestHelpers.with_env('OTEL_SEMCONV_STABILITY_OPT_IN' => '') do
        _(instrumentation.send(:determine_semconv)).must_equal('stable')
      end
    end
  end
end
