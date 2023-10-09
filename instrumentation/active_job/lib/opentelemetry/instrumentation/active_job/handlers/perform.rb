# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Handlers
        # Handles perform.active_job
        class Perform < Default
          def on_start(name, _id, payload)
            tokens = []
            parent_context = OpenTelemetry.propagation.extract(payload.fetch(:job).__otel_headers)

            span_name = span_name_from(payload)

            # TODO: Refactor into a propagation strategy
            propagation_style = otel_config[:propagation_style]
            if propagation_style == :child
              tokens << OpenTelemetry::Context.attach(parent_context)
              span = @tracer.start_span(span_name, kind: :consumer, attributes: @mapper.call(payload))
            else
              span_context = OpenTelemetry::Trace.current_span(parent_context).context
              links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid? && propagation_style == :link
              span = @tracer.start_root_span(span_name, kind: :consumer, attributes: @mapper.call(payload), links: links)
            end

            tokens.concat(attach_consumer_context(span))

            { span: span, ctx_tokens: tokens }
          end

          # This method attaches a span to multiple contexts:
          # 1. Registers the ingress span as the top level ActiveJob span.
          #    This is used later to enrich the ingress span in children, e.g. setting span status to error when a child event like `discard` terminates due to an error
          # 2. Registers the ingress span as the "active" span, which is the default behavior of the SDK.
          # @param span [OpenTelemetry::Trace::Span] the currently active span used to record the exception and set the status
          # @return [Array] Context tokens that must be detached when finished
          def attach_consumer_context(span)
            consumer_context = OpenTelemetry::Trace.context_with_span(span)
            internal_context = OpenTelemetry::Instrumentation::ActiveJob.context_with_span(span, parent_context: consumer_context)

            [consumer_context, internal_context].map { |context| OpenTelemetry::Context.attach(context) }
          end

          # TODO: refactor into a strategy
          def span_name_from(payload)
            "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} process"
          end

          def otel_config
            ActiveJob::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
