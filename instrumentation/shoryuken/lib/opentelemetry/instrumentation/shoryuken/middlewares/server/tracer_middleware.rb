# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Shoryuken
      module Middlewares
        module Server
          # TracerMiddleware propagates context and instruments Shoryuken requests
          # by way of its middleware system
          class TracerMiddleware
            def call(worker_instance, queue, sqs_msg, _body)
              attributes = {
                OpenTelemetry::SemanticConventions::Trace::MESSAGING_SYSTEM => 'shoryuken',
                'code.namespace' => worker_instance.class.name,
                OpenTelemetry::SemanticConventions::Trace::MESSAGING_MESSAGE_ID => sqs_msg.message_id,
                OpenTelemetry::SemanticConventions::Trace::MESSAGING_DESTINATION => queue,
                OpenTelemetry::SemanticConventions::Trace::MESSAGING_DESTINATION_KIND => 'queue',
                OpenTelemetry::SemanticConventions::Trace::MESSAGING_OPERATION => 'process'
              }
              span_name = case instrumentation_config[:span_naming]
                          when :job_class then "#{worker_instance.class.name} process"
                          else "#{queue} process"
                          end

              extracted_context = OpenTelemetry.propagation.extract(sqs_msg)
              OpenTelemetry::Context.with_current(extracted_context) do
                links = []
                span_context = OpenTelemetry::Trace.current_span(extracted_context).context
                links << OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
                span = tracer.start_root_span(span_name, attributes: attributes, links: links, kind: :consumer)
                OpenTelemetry::Trace.with_span(span) do
                  yield
                rescue Exception => e # rubocop:disable Lint/RescueException
                  span.record_exception(e)
                  span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
                  raise e
                ensure
                  span&.finish
                end
              end
            end

            private

            def instrumentation_config
              Shoryuken::Instrumentation.instance.config
            end

            def tracer
              Shoryuken::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
