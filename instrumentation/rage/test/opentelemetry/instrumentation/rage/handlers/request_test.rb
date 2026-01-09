# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../../lib/opentelemetry/instrumentation/rage/handlers/request'

describe OpenTelemetry::Instrumentation::Rage::Handlers::Request do
  subject { OpenTelemetry::Instrumentation::Rage::Handlers::Request }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  before do
    instrumentation.install({})
    EXPORTER.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '.enrich_request_span' do
    let(:controller_class) do
      Class.new do
        def action_name; end
      end
    end
    let(:controller) { controller_class.new }
    let(:request) { double(method: 'PUT', route_uri_pattern: '/api/test/:id') }
    let(:result) { double(error?: false) }

    before do
      stub_const('MyController', controller_class)
      allow(controller).to receive(:action_name).and_return('my_action')
    end

    it 'updates span name and attributes' do
      instrumentation.tracer.in_span('test span') do |span|
        context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)

        OpenTelemetry::Context.with_current(context) do
          subject.enrich_request_span(controller:, request:) { result }
        end

        _(span.name).must_equal('PUT /api/test/:id')

        _(span.attributes['http.route']).must_equal('/api/test/:id')
        _(span.attributes['code.function.name']).must_equal('MyController#my_action')

        _(span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
      end
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        instrumentation.tracer.in_span('test span') do |span|
          context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)

          OpenTelemetry::Context.with_current(context) do
            subject.enrich_request_span(controller:, request:) { result }
          end

          _(span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
          _(span.events.first.name).must_equal 'exception'
          _(span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
        end
      end
    end

    describe 'with inactive span' do
      it 'yields control' do
        span = OpenTelemetry::Trace.non_recording_span(OpenTelemetry::Trace::SpanContext.new)
        context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)
        yielded = false

        OpenTelemetry::Context.with_current(context) do
          subject.enrich_request_span(controller:, request:) do
            yielded = true
          end
        end

        _(yielded).must_equal(true)
      end
    end
  end
end
