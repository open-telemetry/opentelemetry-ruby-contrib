# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Handles enqueue.active_job
        class Enqueue < Default
          def on_start(name, _id, payload)
            otel_config = ActiveJob::Instrumentation.instance.config
            span_name = "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} publish"
            span = @tracer.start_span(span_name, kind: :producer, attributes: @mapper.call(payload))
            tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
            OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire
            { span: span, ctx_tokens: tokens }
          end
        end
      end
    end
  end
end
