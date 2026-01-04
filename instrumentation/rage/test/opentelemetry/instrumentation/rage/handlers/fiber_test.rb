# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rage'
require_relative '../../../../../lib/opentelemetry/instrumentation/rage/handlers/fiber'

describe OpenTelemetry::Instrumentation::Rage::Handlers::Fiber do
  subject { OpenTelemetry::Instrumentation::Rage::Handlers::Fiber }

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rage::Instrumentation.instance }

  before do
    instrumentation.install({})
    EXPORTER.reset
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe 'Patch' do
    let(:klass) do
      Class.new do
        def self.schedule(&)
          yield
        end
      end
    end

    before do
      klass.singleton_class.prepend(subject::Patch)
      Fiber[:__rage_otel_context] = nil
    end

    describe 'without active span' do
      it 'saves context to fiber storage' do
        _(Fiber[:__rage_otel_context]).must_be_nil
        klass.schedule {}
        _(Fiber[:__rage_otel_context]).must_be_instance_of(OpenTelemetry::Context)
      end
    end

    describe 'with active span' do
      it 'saves context to fiber storage' do
        _(Fiber[:__rage_otel_context]).must_be_nil
        instrumentation.tracer.in_span('test span') do
          klass.schedule {}
        end
        _(Fiber[:__rage_otel_context]).must_be_instance_of(OpenTelemetry::Context)
      end
    end

    it 'calls super' do
      klass.stub(:schedule, -> { :test_schedule_result }) do
        _(klass.schedule {}).must_equal(:test_schedule_result)
      end
    end
  end

  describe '#initialize' do
    it 'patches Fiber' do
      expect(Fiber.singleton_class).to receive(:prepend).with(subject::Patch)
      subject.new
    end
  end

  describe '#propagate_otel_context' do
    before do
      allow(Fiber.singleton_class).to receive(:prepend).with(subject::Patch)
    end

    it 'propagates context' do
      instrumentation.tracer.in_span('test span') do
        Fiber[:__rage_otel_context] = OpenTelemetry::Context.current
      end

      subject.new.propagate_otel_context do
        _(OpenTelemetry::Trace.current_span.name).must_equal('test span')
      end
    end

    describe 'with baggage' do
      it 'propagates baggage' do
        Fiber[:__rage_otel_context] = OpenTelemetry::Baggage.set_value('testing_baggage', 'it_worked')

        subject.new.propagate_otel_context do
          _(OpenTelemetry::Baggage.value('testing_baggage')).must_equal('it_worked')
        end
      end
    end
  end
end
