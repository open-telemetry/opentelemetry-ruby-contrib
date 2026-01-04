# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/rage'

describe OpenTelemetry::Instrumentation::Rage do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Rage'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    after do
      instrumentation.instance_variable_set(:@installed, false)
    end

    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end

    it 'installs Rack middleware' do
      expect(Rage.config.middleware).to receive(:insert_after) do |position, (middleware, _, _)|
        _(position).must_equal(0)
        _(middleware.name).must_match(/^OpenTelemetry::Instrumentation::Rack::Middlewares/)
      end

      instrumentation.install({})
    end

    it 'installs observability components' do
      expect(Rage.config.telemetry).to receive(:use).with(OpenTelemetry::Instrumentation::Rage::Handlers::Request)
      expect(Rage.config.telemetry).to receive(:use).with(OpenTelemetry::Instrumentation::Rage::Handlers::Cable)
      expect(Rage.config.telemetry).to receive(:use).with(OpenTelemetry::Instrumentation::Rage::Handlers::Deferred)
      expect(Rage.config.telemetry).to receive(:use).with(OpenTelemetry::Instrumentation::Rage::Handlers::Events)
      expect(Rage.config.telemetry).to receive(:use).with(instance_of(OpenTelemetry::Instrumentation::Rage::Handlers::Fiber))

      expect(Rage.config.log_context).to receive(:<<).with(OpenTelemetry::Instrumentation::Rage::LogContext)

      instrumentation.install({})
    end
  end

  describe '#compatible' do
    describe 'with a compatible version' do
      before do
        stub_const('::Rage::VERSION', '1.22.1')
      end

      it 'returns true' do
        _(instrumentation.compatible?).must_equal(true)
      end

      it 'logs a warning' do
        expect(OpenTelemetry.logger).not_to receive(:warn)
        instrumentation.compatible?
      end
    end

    describe 'with an incompatible version' do
      before do
        stub_const('::Rage::VERSION', '1.11.0')
      end

      it 'returns false' do
        _(instrumentation.compatible?).must_equal(false)
      end

      it 'logs a warning' do
        expect(OpenTelemetry.logger).to receive(:warn).with(/1.11.0 is not supported/)
        instrumentation.compatible?
      end
    end
  end
end
