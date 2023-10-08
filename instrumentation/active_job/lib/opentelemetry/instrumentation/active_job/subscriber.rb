# frozen_string_literal: true

require 'active_support/subscriber'

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      # Provides helper methods
      #
      class AttributeMapper
        TEST_ADAPTERS = %w[async inline].freeze

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

          otel_attributes['net.transport'] = 'inproc' if TEST_ADAPTERS.include?(job.class.queue_adapter_name)
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

        def start(name, _id, payload)
          span = @tracer.start_span(name, attributes: @mapper.call(payload))
          tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
          OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire

          payload.merge!(__otel: { span: span, ctx_tokens: tokens })
        end

        def finish(_name, _id, payload)
          begin
            otel = payload.delete(:__otel)
            span = otel&.fetch(:span)
            tokens = otel&.fetch(:ctx_tokens)

            # Unhandled exceptions are reported in `exception_object`
            # while handled exceptions are reported in `error`
            exception = payload[:error] || payload[:exception_object]
            if exception
              status = OpenTelemetry::Trace::Status.error(exception.message)
              OpenTelemetry::Instrumentation::ActiveJob.current_span.status = status
              # Only record the exception on the ActiveSpan
              # This is particularly useful when
              span&.record_exception(exception)
              span&.status = status
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end
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
      end

      # Handles enqueue.active_job
      class EnqueueHandler < DefaultHandler
        def start(name, _id, payload)
          otel_config = ActiveJob::Instrumentation.instance.config
          span_name = "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} publish"
          span = @tracer.start_span(span_name, kind: :producer, attributes: @mapper.call(payload))
          tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
          OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire
          payload.merge!(__otel: { span: span, ctx_tokens: tokens })
        end
      end

      # Handles perform.active_job
      class PerformHandler < DefaultHandler
        def start(name, _id, payload)
          tokens = []
          parent_context = OpenTelemetry.propagation.extract(payload.fetch(:job).__otel_headers)
          span_context = OpenTelemetry::Trace.current_span(parent_context).context

          otel_config = ActiveJob::Instrumentation.instance.config
          span_name = "#{otel_config[:span_naming] == :job_class ? payload.fetch(:job).class.name : payload.fetch(:job).queue_name} process"

          propagation_style = otel_config[:propagation_style]
          if propagation_style == :child
            tokens << OpenTelemetry::Context.attach(parent_context)
            span = @tracer.start_span(span_name, kind: :consumer, attributes: @mapper.call(payload))
          else
            links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid? && propagation_style == :link
            span = @tracer.start_root_span(span_name, kind: :consumer, attributes: @mapper.call(payload), links: links)
          end

          consumer_context = OpenTelemetry::Trace.context_with_span(span)
          aj_context = OpenTelemetry::Instrumentation::ActiveJob.context_with_span(span, parent_context: consumer_context)

          tokens.concat([consumer_context, aj_context].map { |context| OpenTelemetry::Context.attach(context) })

          payload.merge!(__otel: { span: span, ctx_tokens: tokens })
        end
      end

      # Custom subscriber that handles ActiveJob notifications
      class Subscriber < ::ActiveSupport::Subscriber
        attr_reader :tracer

        def initialize(...)
          super
          tracer = Instrumentation.instance.tracer
          mapper = AttributeMapper.new
          default_handler = DefaultHandler.new(tracer, mapper)
          enqueue_handler = EnqueueHandler.new(tracer, mapper)

          @handlers_by_pattern = {
            'enqueue.active_job' => enqueue_handler,
            'enqueue_at.active_job' => enqueue_handler,
            'perform.active_job' => PerformHandler.new(tracer, mapper)
          }
          @handlers_by_pattern.default = default_handler
          @call_super if ::ActiveJob.version < Gem::Version.new('7.1')
        end

        # The methods below are the events the Subscriber is interested in.
        def enqueue_at(...); end
        def enqueue(...); end
        def enqueue_retry(...); end
        # This event causes much heartache as it is the first in a series of events that is triggered.
        # It should not be the ingress span because it does not measure anything.
        # https://github.com/rails/rails/blob/v6.1.7.6/activejob/lib/active_job/instrumentation.rb#L14
        # https://github.com/rails/rails/blob/v7.0.8/activejob/lib/active_job/instrumentation.rb#L19
        # def perform_start(...); end
        def perform(...); end
        def retry_stopped(...); end
        # def discard(...); end

        def start(name, id, payload)
          @handlers_by_pattern[name].start(name, id, payload)
          # This is nuts
          super if @call_super
        end

        def finish(name, id, payload)
          @handlers_by_pattern[name].finish(name, id, payload)
          # This is equally nuts
          super if @call_super
        end

        def self.install
          attach_to :active_job
          tracer = Instrumentation.instance.tracer
          mapper = AttributeMapper.new
          default_handler = DefaultHandler.new(tracer, mapper)
          @subscriptions = %w[discard.active_job].map do |key|
            ActiveSupport::Notifications.subscribe(key, default_handler)
          end
        end

        def self.uninstall
          detach_from :active_job
          @subscriptions&.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }
        end
      end
    end
  end
end
