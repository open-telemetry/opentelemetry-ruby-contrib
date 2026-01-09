# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../../lib/opentelemetry/instrumentation/rage/handlers/cable'

describe OpenTelemetry::Instrumentation::Rage::Handlers::Cable do
  subject { OpenTelemetry::Instrumentation::Rage::Handlers::Cable }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  describe '.save_context' do
    let(:env) { { 'REQUEST_METHOD' => 'POST', 'PATH_INFO' => '/cable' } }

    describe 'with no active span' do
      it 'does not change env' do
        subject.save_context(env:) {}
        _(env.size).must_equal(2)
      end

      it 'yields control' do
        yielded = false

        subject.save_context(env:) do
          yielded = true
        end

        _(yielded).must_equal(true)
      end
    end

    describe 'with active span' do
      before { instrumentation.install({}) }
      after { instrumentation.instance_variable_set(:@installed, false) }

      it 'updates span name' do
        instrumentation.tracer.in_span('test span') do |span|
          context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)

          OpenTelemetry::Context.with_current(context) do
            subject.save_context(env:) {}
          end

          _(span.name).must_equal('POST /cable')
        end
      end

      it 'updates env' do
        instrumentation.tracer.in_span('test span') do |span|
          context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)

          OpenTelemetry::Context.with_current(context) do
            subject.save_context(env:) {}
          end

          _(env['otel.rage.handshake_context']).must_equal(context)
          _(env['otel.rage.handshake_link'].first).must_be_instance_of(OpenTelemetry::Trace::Link)
        end
      end

      it 'yields control' do
        instrumentation.tracer.in_span('test span') do |span|
          context = OpenTelemetry::Instrumentation::Rack.context_with_span(span)
          yielded = false

          OpenTelemetry::Context.with_current(context) do
            subject.save_context(env:) do
              yielded = true
            end
          end

          _(yielded).must_equal(true)
        end
      end
    end
  end

  describe '.create_connection_span' do
    let(:link) { OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new) }
    let(:env) { { 'otel.rage.handshake_link' => [link] } }
    let(:action) { :my_action }
    let(:connection_class) { Class.new }
    let(:connection) { connection_class.new }
    let(:result) { double(error?: false) }

    let(:finished_spans) { EXPORTER.finished_spans }
    let(:connection_span) { finished_spans.first }

    before do
      instrumentation.install({})
      EXPORTER.reset
      stub_const('MyConnection', connection_class)
    end

    after { instrumentation.instance_variable_set(:@installed, false) }

    it 'creates a span' do
      subject.create_connection_span(env:, action:, connection:) { result }

      _(finished_spans.size).must_equal(1)

      _(connection_span.name).must_equal('MyConnection my_action')
      _(connection_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)

      _(connection_span.attributes['messaging.system']).must_equal('rage.cable')
      _(connection_span.attributes['messaging.destination.name']).must_equal('MyConnection')
      _(connection_span.attributes['code.function.name']).must_equal('MyConnection#my_action')

      _(connection_span.links.first).must_equal(link)
    end

    describe 'with baggage' do
      let(:context) { OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked') }
      let(:env) { { 'otel.rage.handshake_context' => context } }

      it 'propagates baggage' do
        subject.create_connection_span(env:, action:, connection:) do
          _(OpenTelemetry::Baggage.value('testing_baggage')).must_equal('it_worked')
          result
        end
      end
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        subject.create_connection_span(env:, action:, connection:) { result }

        _(connection_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
        _(connection_span.events.first.name).must_equal 'exception'
        _(connection_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end
    end

    describe 'with connect action' do
      let(:action) { :connect }

      it 'sets span kind to server' do
        subject.create_connection_span(env:, action:, connection:) { result }
        _(connection_span.kind).must_equal(:server)
      end
    end

    describe 'with disconnect action' do
      let(:action) { :disconnect }

      it 'sets span kind to internal' do
        subject.create_connection_span(env:, action:, connection:) { result }
        _(connection_span.kind).must_equal(:internal)
      end
    end
  end

  describe '.create_channel_span' do
    let(:link) { OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new) }
    let(:env) { { 'otel.rage.handshake_link' => [link] } }
    let(:action) { :my_action }
    let(:channel_class) { Class.new }
    let(:channel) { channel_class.new }

    let(:result) { double(error?: false) }

    let(:finished_spans) { EXPORTER.finished_spans }
    let(:channel_span) { finished_spans.first }

    before do
      instrumentation.install({})
      EXPORTER.reset
      stub_const('MyChannel', channel_class)
    end

    after { instrumentation.instance_variable_set(:@installed, false) }

    it 'creates a span' do
      subject.create_channel_span(env:, action:, channel:) { result }

      _(finished_spans.size).must_equal(1)

      _(channel_span.name).must_equal('MyChannel receive')
      _(channel_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
      _(channel_span.kind).must_equal(:server)

      _(channel_span.attributes['messaging.system']).must_equal('rage.cable')
      _(channel_span.attributes['messaging.destination.name']).must_equal('MyChannel')
      _(channel_span.attributes['messaging.operation.type']).must_equal('receive')
      _(channel_span.attributes['code.function.name']).must_equal('MyChannel#my_action')

      _(channel_span.links.first).must_equal(link)
    end

    describe 'with baggage' do
      let(:context) { OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked') }
      let(:env) { { 'otel.rage.handshake_context' => context } }

      it 'propagates baggage' do
        subject.create_channel_span(env:, action:, channel:) do
          _(OpenTelemetry::Baggage.value('testing_baggage')).must_equal('it_worked')
          result
        end
      end
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        subject.create_channel_span(env:, action:, channel:) { result }

        _(channel_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
        _(channel_span.events.first.name).must_equal 'exception'
        _(channel_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end
    end

    describe 'with subscribed action' do
      let(:action) { :subscribed }

      it 'sets span kind to server' do
        subject.create_channel_span(env:, action:, channel:) { result }

        _(channel_span.attributes['messaging.operation.type']).must_equal('receive')
        _(channel_span.name).must_equal('MyChannel subscribe')
        _(channel_span.kind).must_equal(:server)
      end
    end

    describe 'with unsubscribed action' do
      let(:action) { :unsubscribed }

      it 'sets span kind to server' do
        subject.create_channel_span(env:, action:, channel:) { result }

        _(channel_span.attributes['messaging.operation.type']).must_be_nil
        _(channel_span.name).must_equal('MyChannel unsubscribe')
        _(channel_span.kind).must_equal(:internal)
      end
    end
  end

  describe '.create_broadcast_span' do
    let(:result) { double(error?: false) }

    let(:finished_spans) { EXPORTER.finished_spans }
    let(:broadcast_span) { finished_spans.first }

    before do
      instrumentation.install({})
      EXPORTER.reset
    end

    after { instrumentation.instance_variable_set(:@installed, false) }

    it 'creates a span' do
      subject.create_broadcast_span(stream: 'test-stream') { result }

      _(finished_spans.size).must_equal(1)

      _(broadcast_span.name).must_equal('Rage::Cable broadcast')
      _(broadcast_span.status.code).must_equal(OpenTelemetry::Trace::Status::UNSET)
      _(broadcast_span.kind).must_equal(:producer)

      _(broadcast_span.attributes['messaging.system']).must_equal('rage.cable')
      _(broadcast_span.attributes['messaging.operation.type']).must_equal('publish')
      _(broadcast_span.attributes['messaging.destination.name']).must_equal('test-stream')
    end

    describe 'with error' do
      let(:result) { double(error?: true, exception: RuntimeError.new) }

      it 'handles returned exceptions' do
        subject.create_broadcast_span(stream: 'test-stream') { result }

        _(broadcast_span.status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
        _(broadcast_span.events.first.name).must_equal 'exception'
        _(broadcast_span.events.first.attributes['exception.type']).must_equal 'RuntimeError'
      end
    end
  end
end
