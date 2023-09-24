# frozen_string_literal: true

require 'active_support/subscriber'

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Patches
        # Module to prepend to ActiveJob::Core for context propagation.
        module Base
          def self.prepended(base)
            base.class_eval do
              attr_accessor :__otel_headers
            end
          end

          def initialize(...)
            @__otel_headers = {}
            super
          end

          def serialize
            message = super

            begin
              message.merge!('__otel_headers' => serialize_arguments(@__otel_headers))
            rescue StandardError => error
              OpenTelemetry.handle_error(exception: error)
            end

            message
          end

          def deserialize(job_data)
            begin
              @__otel_headers = deserialize_arguments(job_data.delete('__otel_headers') || []).to_h
            rescue StandardError => error
              OpenTelemetry.handle_error(exception: error)
            end
            super
          end
          ::ActiveJob::Base.prepend(self)
        end
      end
    end
  end
end

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      class EnqueueSubscriber
        def on_start(name, _id, payload, subscriber)
          span = subscriber.tracer.start_span("#{payload.fetch(:job).queue_name} publish",
          kind: :producer,
          attributes: subscriber.job_attributes(payload.fetch(:job)))
          tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
          OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire
          { span: span, ctx_tokens: tokens }
        end
      end

      class PerformSubscriber
        def on_start(name, _id, payload, subscriber)
          tokens = []
          parent_context = OpenTelemetry.propagation.extract(payload.fetch(:job).__otel_headers)
          span_context = OpenTelemetry::Trace.current_span(parent_context).context

          if span_context.valid?
            tokens << OpenTelemetry::Context.attach(parent_context)
            links = [OpenTelemetry::Trace::Link.new(span_context)]
          end

          span = subscriber.tracer.start_span(
            "#{payload.fetch(:job).queue_name} process",
            kind: :consumer,
            attributes: subscriber.job_attributes(payload.fetch(:job)),
            links: links
          )

          tokens << OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )

          { span: span, ctx_tokens: tokens }
        end
      end

      class Subscriber < ::ActiveSupport::Subscriber
        TEST_ADAPTERS = %w[async inline]
        EVENT_HANDLERS = {
          'enqueue.active_job' => EnqueueSubscriber.new,
          'perform.active_job' => PerformSubscriber.new,
        }

        attach_to :active_job

        # The methods below are the events the Subscriber is interested in.
        def enqueue(...); end
        def perform(...);end

        def start(name, id, payload)
          begin
            payload.merge!(__otel: EVENT_HANDLERS.fetch(name).on_start(name, id, payload, self)) # The payload is _not_ transmitted over the wire
          rescue StandardError => error
            OpenTelemetry.handle_error(exception: error)
          end

          super
        end

        def finish(_name, _id, payload)
          begin
            otel = payload.delete(:__otel)
            span = otel.fetch(:span)
            tokens = otel.fetch(:ctx_tokens)
          rescue StandardError => error
            OpenTelemetry.handle_error(exception: error)
          end

          super

        ensure
          begin
            span&.finish
          rescue StandardError => error
            OpenTelemetry.handle_error(exception: error)
          end
          tokens&.reverse&.each do |token|
            begin
              OpenTelemetry::Context.detach(token)
            rescue StandardError => error
              OpenTelemetry.handle_error(exception: error)
            end
          end
        end

        def on_start(name, _id, payload)
          span = tracer.start_span(name, attributes: job_attributes(payload.fetch(:job)))
          tokens = [OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))]
          OpenTelemetry.propagation.inject(payload.fetch(:job).__otel_headers) # This must be transmitted over the wire
          { span: span, ctx_tokens: tokens }
        end

        def job_attributes(job)
          otel_attributes = {
            'code.namespace' => job.class.name,
            'messaging.destination_kind' => 'queue',
            'messaging.system' => job.class.queue_adapter_name,
            'messaging.destination' => job.queue_name,
            'messaging.message_id' => job.job_id,
            'messaging.active_job.provider_job_id' => job.provider_job_id,
            'messaging.active_job.priority' => job.priority
          }

          otel_attributes['net.transport'] = 'inproc' if TEST_ADAPTERS.include?(job.class.queue_adapter_name)
          otel_attributes.compact!

          otel_attributes
        end

        def tracer
          OpenTelemetry.tracer_provider.tracer('otel-active_job', '0.0.1')
        end
      end
    end
  end
end
