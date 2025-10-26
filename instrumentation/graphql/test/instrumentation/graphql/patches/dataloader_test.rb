# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/graphql'
require_relative '../../../../lib/opentelemetry/instrumentation/graphql/patches/dataloader'

describe OpenTelemetry::Instrumentation::GraphQL::Patches::Dataloader do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer('test') }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install({})
  end

  if OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance.dataloader_has_spawn_fiber?
    describe '#spawn_fiber' do
      it 'set context in the child fiber' do
        tracer.in_span('parent') do
          fiber = GraphQL::Dataloader.new.spawn_fiber do
            tracer.in_span('child1') do
              # empty block
            end
            Fiber.yield
            tracer.in_span('child2') do
              # empty block
            end
          end
          fiber.resume
          fiber.resume
        end

        parent_span = spans.find { |s| s.name == 'parent' }
        child1_span = spans.find { |s| s.name == 'child1' }
        child2_span = spans.find { |s| s.name == 'child2' }

        _(parent_span.span_id).must_equal(child1_span.parent_span_id)
        _(parent_span.span_id).must_equal(child2_span.parent_span_id)
      end
    end
  end
end
