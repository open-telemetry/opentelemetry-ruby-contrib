# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/semconv/incubating/code'
require 'opentelemetry/semconv/incubating/messaging'

module OpenTelemetry
  module Instrumentation
    module Rage
      module Handlers
        # The class propagates OpenTelemetry context to deferred tasks and wraps the
        # enqueuing and processing of deferred tasks in spans.
        class Deferred < ::Rage::Telemetry::Handler
          handle 'deferred.task.enqueue', with: :create_enqueue_span
          handle 'deferred.task.process', with: :create_perform_span

          # @param task_class [Class] the class of the deferred task
          # @param task_context [Hash] the context for the deferred task
          def self.create_enqueue_span(task_class:, task_context:)
            attributes = {
              SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.deferred',
              SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE => 'send',
              SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => task_class.name,
              SemConv::Incubating::CODE::CODE_FUNCTION_NAME => "#{task_class}.enqueue"
            }

            Rage::Instrumentation.instance.tracer.in_span("#{task_class} enqueue", attributes:, kind: :producer) do |span|
              OpenTelemetry.propagation.inject(task_context)

              result = yield

              if result.error?
                span.record_exception(result.exception)
                span.status = OpenTelemetry::Trace::Status.error
              end
            end
          end

          # @param task_class [Class] the class of the deferred task
          # @param task [Rage::Deferred::Task] the deferred task instance
          # @param task_context [Hash] the context for the deferred task
          def self.create_perform_span(task_class:, task:, task_context:)
            otel_context = OpenTelemetry.propagation.extract(task_context)

            OpenTelemetry::Context.with_current(otel_context) do
              attributes = {
                SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.deferred',
                SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE => 'process',
                SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => task_class.name,
                SemConv::Incubating::CODE::CODE_FUNCTION_NAME => "#{task_class}#perform"
              }

              attributes['messaging.message.delivery_attempt'] = task.meta.attempts if task.meta.retrying?

              parent_span_context = OpenTelemetry::Trace.current_span(otel_context).context
              links = [OpenTelemetry::Trace::Link.new(parent_span_context)] if parent_span_context.valid?

              span = Rage::Instrumentation.instance.tracer.start_root_span(
                "#{task_class} perform",
                attributes:,
                links:,
                kind: :consumer
              )

              OpenTelemetry::Trace.with_span(span) do
                result = yield

                if result.error?
                  span.record_exception(result.exception)
                  span.status = OpenTelemetry::Trace::Status.error
                end
              ensure
                span.finish
              end
            end
          end
        end
      end
    end
  end
end
