# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Client
          # TracerMiddleware propagates context and instruments Sidekiq client
          # by way of its middleware system
          class TracerMiddleware
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
              end.tap do
                # FIXME: is it possible to detect failures here? Does sidekiq bubble them up the middlewares?
                if instrumentation_config[:metrics]
                  begin
                    counter_attributes = {
                      'messaging.operation.name' => 'enqueue', # FIXME: metrics semconv
                      'messaging.system' => 'sidekiq', # FIXME: metrics semconv
                      'messaging.destination.name' => job['queue'] # FIXME: metrics semconv
                      # server.address => # FIXME: required if available
                      # messaging.destination.partition.id => FIXME: recommended
                      # server.port => # FIXME: recommended
                    }

                    counter = meter.create_counter('messaging.client.sent.messages')
                    counter.add(1, attributes: counter_attributes)
                  end
                end
              end
            end

            private

            def instrumentation_config
              Sidekiq::Instrumentation.instance.config
            end

            def tracer
              Sidekiq::Instrumentation.instance.tracer
            end

            def meter
              Sidekiq::Instrumentation.instance.meter
            end
          end
        end
      end
    end
  end
end
