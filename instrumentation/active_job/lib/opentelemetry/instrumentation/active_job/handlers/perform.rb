# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Handles perform.active_job to generate ingress spans
        class Perform < Default
          EVENT_NAME = 'process'

          # Overrides the `Default#start_span` method to create an ingress span
          # and registers it with the current context
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing job run information
          # @return [Hash] with the span and generated context tokens
          def start_span(name, _id, payload)
            job = payload.fetch(:job)
            span_name = span_name(job, EVENT_NAME)
            parent_context = OpenTelemetry.propagation.extract(job.__otel_headers)

            # TODO: Refactor into a propagation strategy
            propagation_style = @config[:propagation_style]
            if propagation_style == :child
              span = tracer.start_span(span_name, with_parent: parent_context, kind: :consumer, attributes: @mapper.call(payload))
            else
              span_context = OpenTelemetry::Trace.current_span(parent_context).context
              links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid? && propagation_style == :link
              span = tracer.start_root_span(span_name, kind: :consumer, attributes: @mapper.call(payload), links: links)
            end

            { span: span, ctx_token: attach_consumer_context(span, parent_context) }
          end

          # Overrides `Default#start` to optionally snapshot performance metrics at job start
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing job run information
          # @return [Hash] the payload passed as a method argument
          def start(name, id, payload)
            payload[:__otel] = start_span(name, id, payload)
            payload[:__otel_metrics] = snapshot_metrics if @config[:enable_performance_metrics]
            payload
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Overrides `Default#finish` to optionally record performance metrics on the span
          #
          # @param _name [String] of the Event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] containing job run information
          def finish(_name, _id, payload)
            otel = payload.delete(:__otel)
            metrics_start = payload.delete(:__otel_metrics)
            span = otel&.fetch(:span)
            token = otel&.fetch(:ctx_token)

            record_metrics(span, metrics_start) if span && metrics_start
            on_exception(payload[:error] || payload[:exception_object], span)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          ensure
            finish_span(span, token)
          end

          # This method attaches a span to multiple contexts:
          # 1. Registers the ingress span as the top level ActiveJob span.
          #    This is used later to enrich the ingress span in children, e.g. setting span status to error when a child event like `discard` terminates due to an error
          # 2. Registers the ingress span as the "active" span, which is the default behavior of the SDK.
          # @param span [OpenTelemetry::Trace::Span] the currently active span used to record the exception and set the status
          # @param parent_context [Context] The context to use as the parent for the consumer context
          # @return [Numeric] Context token that must be detached when finished
          def attach_consumer_context(span, parent_context)
            consumer_context = OpenTelemetry::Trace.context_with_span(span, parent_context: parent_context)
            internal_context = OpenTelemetry::Instrumentation::ActiveJob.context_with_span(span, parent_context: consumer_context)

            OpenTelemetry::Context.attach(internal_context)
          end

          private

          def snapshot_metrics
            {
              monotonic_time: Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond),
              cpu_time: now_cpu,
              gc_time: now_gc,
              allocations: now_allocations
            }
          end

          def record_metrics(span, start)
            finish = snapshot_metrics

            duration = finish[:monotonic_time] - start[:monotonic_time]
            cpu_time = finish[:cpu_time] - start[:cpu_time]
            cpu_utilization = duration.positive? ? (cpu_time / duration).clamp(0.0, 1.0) : 0.0
            gc_time = (finish[:gc_time] - start[:gc_time]) / 1_000_000.0
            allocations = finish[:allocations] - start[:allocations]

            span.set_attribute('rails.cpu.time', cpu_time)
            span.set_attribute('rails.cpu.utilization', cpu_utilization)
            span.set_attribute('rails.gc.time', gc_time)
            span.set_attribute('rails.memory.allocations', allocations)
          end

          if GC.respond_to?(:total_time)
            # Returns total GC time in nanoseconds.
            def now_gc
              GC.total_time
            end
          else
            # Returns zero when total GC time is unavailable.
            def now_gc
              0
            end
          end

          begin
            Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :float_millisecond)

            # Returns current thread CPU time in milliseconds.
            def now_cpu
              Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID, :float_millisecond)
            end
          rescue StandardError
            # Returns zero when current thread CPU time is unavailable.
            def now_cpu
              0.0
            end
          end

          if GC.stat.key?(:total_allocated_objects)
            # Returns total allocated objects.
            def now_allocations
              GC.stat(:total_allocated_objects)
            end
          else
            # Returns zero when total allocated objects is unavailable.
            def now_allocations
              0
            end
          end
        end
      end
    end
  end
end
