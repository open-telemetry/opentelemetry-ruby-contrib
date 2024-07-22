# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Handles `enqueue.active_job` and `enqueue_at.active_job` to generate egress spans
        class Enqueue < Default
          # Overrides the `Default#start_span` method to create an egress span
          # and registers it with the current context
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing job run information
          # @return [Hash] with the span and generated context tokens
          def start_span(name, _id, payload)
            job = payload.fetch(:job)
            span = tracer.start_span(span_name(job), kind: :producer, attributes: @mapper.call(payload))
            OpenTelemetry.propagation.inject(job.__otel_headers) # This must be transmitted over the wire
            { span: span, ctx_token: OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span)) }
          end

          private

          def span_name(job)
            prefix = if @config[:span_naming] == :job_class
                       job.class.name
                     else
                       job.queue_name
                     end

            "#{prefix} publish"
          end
        end
      end
    end
  end
end
