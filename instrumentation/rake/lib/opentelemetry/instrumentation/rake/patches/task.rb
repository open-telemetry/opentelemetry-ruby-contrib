# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Rake
      module Patches
        # Module to prepend to Rask::Task for instrumentation
        module Task
          def invoke(*args)
            attributes = { 'rake.task' => name }
            tracer.in_span('rake.invoke', attributes: attributes) do
              super
            end
          end

          def execute(args = nil)
            attributes = { 'rake.task' => name }
            tracer.in_span('rake.execute', attributes: attributes) do
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
