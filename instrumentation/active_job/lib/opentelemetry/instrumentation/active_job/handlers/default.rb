# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Default handler to create internal spans for events
        # This class provides default template methods that derived classes may override to generate spans and register contexts.
        class Default
          # @param parent_span_provider [Object] provides access to the top most parent span (usually the ingress span)
          # @param mapper [Callable] converts ActiveSupport::Notifications payloads to span attributes
          # @param config [Hash] of instrumentation options
          def initialize(parent_span_provider, mapper, config)
            @mapper = mapper
            @config = config
            @parent_span_provider = parent_span_provider
          end

          # Invoked by ActiveSupport::Notifications at the start of the instrumentation block
          # It amends the otel context of a Span and Context tokens to the payload
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing job run information
          # @return [Hash] the payload passed as a method argument
          def start(name, id, payload)
            payload.merge!(__otel: start_span(name, id, payload))
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Creates a span and registers it with the current context
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing job run information
          # @return [Hash] with the span and generated context tokens
          def start_span(name, _id, payload)
            span = tracer.start_span(name, attributes: @mapper.call(payload))
            tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]

            { span: span, ctx_tokens: tokens }
          end

          # Creates a span and registers it with the current context
          #
          # @param _name [String] of the Event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] containing job run information
          # @return [Hash] with the span and generated context tokens
          def finish(_name, _id, payload)
            otel = payload.delete(:__otel)
            span = otel&.fetch(:span)
            tokens = otel&.fetch(:ctx_tokens)

            on_exception((payload[:error] || payload[:exception_object]), span)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          ensure
            finish_span(span, tokens)
          end

          # Finishes the provided spans and also detaches the associated contexts
          #
          # @param span [OpenTelemetry::Trace::Span]
          # @param tokens [Array] to unregister
          def finish_span(span, tokens)
            # closes the span after all attributes have been finalized
            begin
              if span&.recording?
                span.status = OpenTelemetry::Trace::Status.ok if span.status.code == OpenTelemetry::Trace::Status::UNSET
                span.finish
              end
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e)
            end

            # pops the context stack
            tokens&.reverse_each do |token|
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
            return unless exception && span

            span.record_exception(exception)
            span.status =
              @parent_span_provider.current_span.status =
                OpenTelemetry::Trace::Status.error("Unexpected ActiveJob Error #{exception.class.name}")
          end

          def tracer
            OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
