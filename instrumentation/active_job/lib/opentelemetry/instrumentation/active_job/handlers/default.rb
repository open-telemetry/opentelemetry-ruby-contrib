# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Default handler to creates internal spans for events
        class Default
          def initialize(tracer, mapper)
            @tracer = tracer
            @mapper = mapper
          end

          def start(name, id, payload)
            payload.merge!(__otel: on_start(name, id, payload))
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          def on_start(name, _id, payload)
            span = @tracer.start_span(name, attributes: @mapper.call(payload))
            tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]

            { span: span, ctx_tokens: tokens }
          end

          def finish(_name, _id, payload)
            otel = payload.delete(:__otel)
            span = otel&.fetch(:span)
            tokens = otel&.fetch(:ctx_tokens)

            exception = payload[:error] || payload[:exception_object]
            on_exception(exception, span) if exception
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          ensure
            finish_span(span, tokens)
          end

          def finish_span(span, tokens)
            # closes the span after all attributes have been finalized
            begin
              span&.status = OpenTelemetry::Trace::Status.ok if span&.status&.code == OpenTelemetry::Trace::Status::UNSET
              span&.finish
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e)
            end

            # pops the context stack
            tokens&.reverse&.each do |token|
              OpenTelemetry::Context.detach(token)
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e)
            end
          end

          # Records exceptions on spans and sets Span statuses to `Error`
          #
          # Handled exceptions are recorded on internal spans related to the event. E.g. `discard` events are recorded on the `discard.active_job` span
          # Handled exceptions _are not_ copied to the ingress span, but it does set the status to `Error` making it easier to know that a job has failed
          # Unhandled exceptions bubble up to the ingress span and are recorded there.
          #
          # @param [Exception] exception to report as a Span Event
          # @param [OpenTelemetry::Trace::Span] the currently active span used to record the exception and set the status
          def on_exception(exception, span)
            status = OpenTelemetry::Trace::Status.error(exception.message)
            OpenTelemetry::Instrumentation::ActiveJob.current_span.status = status
            span&.record_exception(exception)
            span&.status = status
          end
        end
      end
    end
  end
end
