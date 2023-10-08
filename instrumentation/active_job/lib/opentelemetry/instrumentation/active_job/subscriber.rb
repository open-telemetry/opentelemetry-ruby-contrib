# frozen_string_literal: true

require 'active_support/subscriber'

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      # Maps ActiveJob Attributes to Semantic Conventions
      #
      # This follows the General and Messaging semantic conventions and uses `rails.active_job.*` namespace for custom attributes
      class AttributeMapper
        def call(payload)
          job = payload.fetch(:job)

          otel_attributes = {
            'code.namespace' => job.class.name,
            'messaging.destination_kind' => 'queue',
            'messaging.system' => job.class.queue_adapter_name,
            'messaging.destination' => job.queue_name,
            'messaging.message_id' => job.job_id,
            'rails.active_job.execution.counter' => job.executions.to_i,
            'rails.active_job.provider_job_id' => job.provider_job_id.to_s,
            'rails.active_job.priority' => job.priority,
            'rails.active_job.scheduled_at' => job.scheduled_at&.to_f
          }

          otel_attributes.compact!

          otel_attributes
        end
      end

      # Default handler to creates internal spans for events
      class DefaultHandler
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

          # Unhandled exceptions are reported in `exception_object`
          # while handled exceptions are reported in `error`
          exception = payload[:error] || payload[:exception_object]
          on_exception(exception, span) if exception
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e)
        ensure
          begin
            span&.finish
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end
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

      # Handles enqueue.active_job
      class EnqueueHandler < DefaultHandler
        def on_start(name, _id, payload)
          otel_config = ActiveJob::Instrumentation.instance.config
          span_name = "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} publish"
          span = @tracer.start_span(span_name, kind: :producer, attributes: @mapper.call(payload))
          tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
          OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire
          { span: span, ctx_tokens: tokens }
        end
      end

      # Handles perform.active_job
      class PerformHandler < DefaultHandler
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
          aj_context = OpenTelemetry::Instrumentation::ActiveJob.context_with_span(span, parent_context: consumer_context)

          [consumer_context, aj_context].map { |context| OpenTelemetry::Context.attach(context) }
        end

        # TODO: refactor into a strategy
        def span_name_from(payload)
          "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} process"
        end

        def otel_config
          ActiveJob::Instrumentation.instance.config
        end
      end

      # Custom subscriber that handles ActiveJob notifications
      class Subscriber
        def self.install
          return unless Array(@subscriptions).empty?

          tracer = Instrumentation.instance.tracer
          mapper = AttributeMapper.new

          default_handler = DefaultHandler.new(tracer, mapper)
          enqueue_handler = EnqueueHandler.new(tracer, mapper)
          perform_handler = PerformHandler.new(tracer, mapper)

          # Why no perform_start?
          # This event causes much heartache as it is the first in a series of events that is triggered.
          # It should not be the ingress span because it does not measure anything.
          # https://github.com/rails/rails/blob/v6.1.7.6/activejob/lib/active_job/instrumentation.rb#L14
          # https://github.com/rails/rails/blob/v7.0.8/activejob/lib/active_job/instrumentation.rb#L19
          handlers_by_pattern = {
            'enqueue' => enqueue_handler,
            'enqueue_at' => enqueue_handler,
            'enqueue_retry' => default_handler,
            'perform' => perform_handler,
            'retry_stopped' => default_handler,
            'discard' => default_handler
          }

          @subscriptions = handlers_by_pattern.map do |key, handler|
            ActiveSupport::Notifications.subscribe("#{key}.active_job", handler)
          end
        end

        def self.uninstall
          @subscriptions&.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }
          @subscriptions = nil
        end
      end
    end
  end
end
