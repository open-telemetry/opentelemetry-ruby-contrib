# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/rack/middlewares/tracer_middleware_with_metrics'
require_relative '../../../../lib/opentelemetry/instrumentation/rack/middlewares/event_handler_with_metrics'
require_relative '../../../../lib/opentelemetry/instrumentation/rack/middlewares/stable/event_handler'

describe OpenTelemetry::Instrumentation::Rack::Instrumentation do
  let(:instrumentation_class) { OpenTelemetry::Instrumentation::Rack::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }
  let(:config) { {} }

  before do
    skip unless ENV['BUNDLE_GEMFILE'].include?('http')

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

  describe '#middleware_args_stable' do
    before do
      instrumentation.install(config)
    end

    describe 'when rack events are configured' do
      let(:config) { Hash(use_rack_events: true) }

      it 'includes metrics event handler when using rack events xuan' do
        args = instrumentation.middleware_args_stable

        puts "args: #{args}"
        _(args[0]).must_equal Rack::Events
        _(args[1].size).must_equal 2
        _(args[1][0]).must_be_instance_of OpenTelemetry::Instrumentation::Rack::Middlewares::Stable::EventHandler
        _(args[1][1]).must_be_instance_of OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandlerWithMetrics
      end
    end

    describe 'when rack events are disabled' do
      let(:config) { Hash(use_rack_events: false) }

      it 'uses TracerMiddlewareWithMetrics' do
        args = instrumentation.middleware_args_stable
        _(args).must_equal [OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddlewareWithMetrics]
      end
    end
  end

  describe '#initialize_metrics' do
    let(:meter_provider) { OpenTelemetry.meter_provider }
    let(:meter) { meter_provider.meter('test-meter') }

    it 'initializes server_request_duration histogram when meter is available' do
      instrumentation.stub(:meter, meter) do
        instrumentation.install(config)
        histogram = instrumentation.config[:server_request_duration]
        _(histogram).wont_be_nil
        _(histogram).must_respond_to :record
      end
    end

    it 'does not create metrics when meter is nil' do
      instrumentation.stub(:meter, nil) do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(config)
        _(instrumentation.config[:server_request_duration]).must_be_nil
      end
    end
  end
end
