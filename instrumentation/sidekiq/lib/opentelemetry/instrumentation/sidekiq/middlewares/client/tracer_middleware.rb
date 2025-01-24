# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../common'

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Client
          # TracerMiddleware propagates context and instruments Sidekiq client
          # by way of its middleware system
          class TracerMiddleware
            include Common
            include ::Sidekiq::ClientMiddleware if defined?(::Sidekiq::ClientMiddleware)

            def call(_worker_class, job, _queue, _redis_pool)
              attributes = {
                SemanticConventions::Trace::MESSAGING_SYSTEM => 'sidekiq',
                'messaging.sidekiq.job_class' => job['wrapped']&.to_s || job['class'],
                SemanticConventions::Trace::MESSAGING_MESSAGE_ID => job['jid'],
                SemanticConventions::Trace::MESSAGING_DESTINATION => job['queue'],
                SemanticConventions::Trace::MESSAGING_DESTINATION_KIND => 'queue'
              }
              attributes[SemanticConventions::Trace::PEER_SERVICE] = instrumentation_config[:peer_service] if instrumentation_config[:peer_service]

              span_name = case instrumentation_config[:span_naming]
                          when :job_class then "#{job['wrapped']&.to_s || job['class']} publish"
                          else "#{job['queue']} publish"
                          end

              tracer.in_span(span_name, attributes: attributes, kind: :producer) do |span|
                OpenTelemetry.propagation.inject(job)
                span.add_event('created_at', timestamp: job['created_at'])
                yield
              end.tap do # rubocop: disable Style/MultilineBlockChain
                count_sent_message(job)
              end
            end

            private

            def count_sent_message(job)
              with_meter do |_meter|
                counter_attributes = metrics_attributes(job).merge(
                  {
                    'messaging.operation.name' => 'create'
                    # server.address => # FIXME: required if available
                    # messaging.destination.partition.id => FIXME: recommended
                    # server.port => # FIXME: recommended
                  }
                )

                counter = messaging_client_sent_messages_counter
                counter.add(1, attributes: counter_attributes)
              end
            end

            def messaging_client_sent_messages_counter
              instrumentation.counter('messaging.client.sent.messages')
            end

            def tracer
              instrumentation.tracer
            end

            def with_meter(&block)
              instrumentation.with_meter(&block)
            end

            def metrics_attributes(job)
              {
                'messaging.system' => 'sidekiq', # FIXME: metrics semconv
                'messaging.destination.name' => job['queue'] # FIXME: metrics semconv
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
