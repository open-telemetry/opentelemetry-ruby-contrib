# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../common'

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Server
          # TracerMiddleware propagates context and instruments Sidekiq requests
          # by way of its middleware system
          class TracerMiddleware
            include Common
            include ::Sidekiq::ServerMiddleware if defined?(::Sidekiq::ServerMiddleware)

            def call(_worker, msg, _queue)
              attributes = {
                SemanticConventions::Trace::MESSAGING_SYSTEM => 'sidekiq',
                'messaging.sidekiq.job_class' => msg['wrapped']&.to_s || msg['class'],
                SemanticConventions::Trace::MESSAGING_MESSAGE_ID => msg['jid'],
                SemanticConventions::Trace::MESSAGING_DESTINATION => msg['queue'],
                SemanticConventions::Trace::MESSAGING_DESTINATION_KIND => 'queue',
                SemanticConventions::Trace::MESSAGING_OPERATION => 'process'
              }
              attributes[SemanticConventions::Trace::PEER_SERVICE] = instrumentation_config[:peer_service] if instrumentation_config[:peer_service]

              span_name = case instrumentation_config[:span_naming]
                          when :job_class then "#{msg['wrapped']&.to_s || msg['class']} process"
                          else "#{msg['queue']} process"
                          end

              extracted_context = OpenTelemetry.propagation.extract(msg)
              OpenTelemetry::Context.with_current(extracted_context) do
                track_queue_latency(msg)

                timed(track_process_time_callback(msg)) do
                  if instrumentation_config[:propagation_style] == :child
                    tracer.in_span(span_name, attributes: attributes, kind: :consumer) do |span|
                      span.add_event('created_at', timestamp: msg['created_at'])
                      span.add_event('enqueued_at', timestamp: msg['enqueued_at'])
                      yield
                    end
                  else
                    links = []
                    span_context = OpenTelemetry::Trace.current_span(extracted_context).context
                    links << OpenTelemetry::Trace::Link.new(span_context) if instrumentation_config[:propagation_style] == :link && span_context.valid?
                    span = tracer.start_root_span(span_name, attributes: attributes, links: links, kind: :consumer)
                    OpenTelemetry::Trace.with_span(span) do
                      span.add_event('created_at', timestamp: msg['created_at'])
                      span.add_event('enqueued_at', timestamp: msg['enqueued_at'])
                      yield
                    rescue Exception => e # rubocop:disable Lint/RescueException
                      span.record_exception(e)
                      span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
                      raise e
                    ensure
                      span.finish
                    end
                  end
                end

                count_consumed_message(msg)
              end
            end

            private

            def track_queue_latency(msg)
              with_meter do
                return unless (enqueued_at = msg['enqueued_at'])
                return unless enqueued_at.is_a?(Numeric)

                latency = (realtime_now - enqueued_at).abs

                queue_latency_gauge&.record(latency, attributes: metrics_attributes(msg))
              end
            end

            def track_process_time_callback(msg)
              ->(duration) { track_process_time(msg, duration) }
            end

            def track_process_time(msg, duration)
              with_meter do
                attributes = metrics_attributes(msg).merge(
                  { 'messaging.operation.name' => 'process' }
                )
                messaging_process_duration_histogram&.record(duration, attributes: attributes)
              end
            end

            def messaging_process_duration_histogram
              instrumentation.histogram('messaging.process.duration')
            end

            def count_consumed_message(msg)
              with_meter do
                messaging_client_consumed_messages_counter.add(1, attributes: metrics_attributes(msg))
              end
            end

            def messaging_client_consumed_messages_counter
              instrumentation.counter('messaging.client.consumed.messages')
            end

            def queue_latency_gauge
              instrumentation.gauge('messaging.queue.latency')
            end

            # FIXME: dedupe
            def metrics_attributes(msg)
              {
                'messaging.system' => 'sidekiq', # FIXME: metrics semconv
                'messaging.destination.name' => msg['queue'] # FIXME: metrics semconv
                # server.address => # FIXME: required if available
                # messaging.destination.partition.id => FIXME: recommended
                # server.port => # FIXME: recommended
              }
            end
          end
        end
      end
    end
  end
end
