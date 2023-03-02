# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rack::Instrumentation do
  let(:instrumentation_class) { OpenTelemetry::Instrumentation::Rack::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }
  let(:config) { {} }

  before do
    # simulate a fresh install:
    instrumentation.instance_variable_set('@installed', false)
  end

  describe 'given default config options' do
    before do
      instrumentation.install(config)
    end

    it 'is installed with default settings' do
      _(instrumentation).must_be :installed?
      _(instrumentation.config[:allowed_request_headers]).must_be_empty
      _(instrumentation.config[:allowed_response_headers]).must_be_empty
      _(instrumentation.config[:application]).must_be_nil
      _(instrumentation.config[:record_frontend_span]).must_equal false
      _(instrumentation.config[:untraced_endpoints]).must_be_empty
      _(instrumentation.config[:url_quantization]).must_be_nil
      _(instrumentation.config[:untraced_requests]).must_be_nil
      _(instrumentation.config[:response_propagators]).must_be_empty
    end
  end

  describe 'when rack gem does not exist' do
    before do
      hide_const('Rack')
      instrumentation.install(config)
    end

    it 'skips installation' do
      _(instrumentation).wont_be :installed?
      _(instrumentation.config[:allowed_request_headers]).must_be_empty
      _(instrumentation.config[:allowed_response_headers]).must_be_empty
      _(instrumentation.config[:application]).must_be_nil
      _(instrumentation.config[:record_frontend_span]).must_equal false
      _(instrumentation.config[:untraced_endpoints]).must_be_empty
      _(instrumentation.config[:url_quantization]).must_be_nil
      _(instrumentation.config[:untraced_requests]).must_be_nil
      _(instrumentation.config[:response_propagators]).must_be_empty
    end
  end
end
