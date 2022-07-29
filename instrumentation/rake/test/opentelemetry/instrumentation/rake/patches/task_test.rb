# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'rake'

require_relative '../../../../../lib/opentelemetry/instrumentation/rake/patches/task'

describe OpenTelemetry::Instrumentation::Rake::Patches::Task do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rake::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  let(:task_name) { :test_rake_instrumentation }
  let(:task) { Rake::Task[task_name] }

  let(:invoke_span) { spans.find { |s| s.name == 'rake.invoke' } }
  let(:execute_span) { spans.find { |s| s.name == 'rake.execute' && s.attributes['rake.task'] == task_name.to_s } }

  before do
    exporter.reset
    instrumentation.install

    Rake::Task.define_task(task_name)
    task.reenable
  end

  describe '#execute' do
    it 'creates an execute span' do
      task.execute

      _(spans.size).must_equal 1

      _(execute_span.kind).must_equal :internal
      _(execute_span.name).must_equal 'rake.execute'
      _(execute_span.attributes['rake.task']).must_equal 'test_rake_instrumentation'
    end
  end

  describe '#invoke' do
    it 'creates invoke and execute spans' do
      task.invoke

      _(spans.size).must_equal 2

      _(invoke_span.kind).must_equal :internal
      _(invoke_span.name).must_equal 'rake.invoke'
      _(invoke_span.attributes['rake.task']).must_equal 'test_rake_instrumentation'

      _(execute_span.kind).must_equal :internal
      _(execute_span.name).must_equal 'rake.execute'
      _(execute_span.attributes['rake.task']).must_equal 'test_rake_instrumentation'
      _(execute_span.parent_span_id).must_equal(invoke_span.span_id)
    end

    describe 'with a prerequisite task' do
      before do
        Rake::Task.define_task(prerequisite_task_name)
        Rake::Task.define_task(task_name => prerequisite_task_name)
      end

      let(:prerequisite_task_name) { :test_rake_instrumentation_prerequisite }
      let(:prerequisite_task_execute_span) do
        spans.find { |s| s.name == 'rake.execute' && s.attributes['rake.task'] == prerequisite_task_name.to_s }
      end

      it 'creates invoke, execute, and prerequisite spans' do
        task.invoke

        _(spans.size).must_equal 3

        _(invoke_span.kind).must_equal :internal
        _(invoke_span.name).must_equal 'rake.invoke'
        _(invoke_span.attributes['rake.task']).must_equal 'test_rake_instrumentation'

        _(execute_span.kind).must_equal :internal
        _(execute_span.name).must_equal 'rake.execute'
        _(execute_span.attributes['rake.task']).must_equal 'test_rake_instrumentation'
        _(execute_span.parent_span_id).must_equal(invoke_span.span_id)

        _(prerequisite_task_execute_span.kind).must_equal :internal
        _(prerequisite_task_execute_span.name).must_equal 'rake.execute'
        _(prerequisite_task_execute_span.attributes['rake.task']).must_equal 'test_rake_instrumentation_prerequisite'
        _(prerequisite_task_execute_span.parent_span_id).must_equal(invoke_span.span_id)
      end
    end
  end
end
