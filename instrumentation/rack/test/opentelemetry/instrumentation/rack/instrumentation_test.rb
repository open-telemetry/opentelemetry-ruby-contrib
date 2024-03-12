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
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.config.clear
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
      _(instrumentation.config[:propagate_with_link]).must_be_nil
      _(instrumentation.config[:untraced_requests]).must_be_nil
      _(instrumentation.config[:response_propagators]).must_be_empty
      _(instrumentation.config[:use_rack_events]).must_equal true
    end
  end

  describe 'when rack gem does not exist' do
    before do
      hide_const('Rack')
      instrumentation.install(config)
    end

    it 'skips installation' do
      _(instrumentation).wont_be :installed?
    end
  end

  describe '#middleware_args' do
    before do
      instrumentation.install(config)
    end

    describe 'when rack events are configured' do
      let(:config) { Hash(use_rack_events: true) }

      it 'instantiates a custom event handler' do
        args = instrumentation.middleware_args
        _(args[0]).must_equal Rack::Events
        _(args[1][0]).must_be_instance_of OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler
      end
    end

    describe 'when rack events are disabled' do
      let(:config) { Hash(use_rack_events: false) }

      it 'instantiates a custom middleware' do
        args = instrumentation.middleware_args
        _(args).must_equal [OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware]
      end
    end
  end
end
