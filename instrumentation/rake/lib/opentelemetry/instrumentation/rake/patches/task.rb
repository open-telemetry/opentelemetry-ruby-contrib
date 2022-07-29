# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Rake
      module Patches
        # Module to prepend to Rask::Task for instrumentation
        module Task
          def invoke(*args)
            tracer.in_span('rake.invoke', attributes: { 'rake.task' => name }) do
              super
            end
          end

          def execute(args = nil)
            tracer.in_span('rake.execute', attributes: { 'rake.task' => name }) do
              super
            end
          end

          private

          def tracer
            Rake::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
