# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Rake
      module Patches
        # Module to prepend to Rask::Task for instrumentation
        module Task
          def invoke(*args)
            span_name = rake_span_name('invoke', name)
            tracer.in_span(span_name, attributes: { 'rake.task' => name, 'rake.execution.type' => 'invoke' }) do
              super
            end
          ensure
            force_flush
          end

          def execute(args = nil)
            span_name = rake_span_name('execute', name)
            tracer.in_span(span_name, attributes: { 'rake.task' => name, 'rake.execution.type' => 'execute' }) do
              super
            end
          ensure
            force_flush
          end

          private

          def tracer
            Rake::Instrumentation.instance.tracer
          end

          def config
            OpenTelemetry::Instrumentation::Rake::Instrumentation.instance.config
          end

          def rake_span_name(execution_type, task_name)
            if config[:span_name] == :execution_type_and_task_name
              "rake.#{execution_type} #{task_name}"
            else
              "rake.#{execution_type}"
            end
          end

          def force_flush
            top_level_task_names = ::Rake.application.top_level_tasks.map { |t| t.split('[').first }

            return unless top_level_task_names.include?(name)

            OpenTelemetry.tracer_provider.force_flush
          end
        end
      end
    end
  end
end
