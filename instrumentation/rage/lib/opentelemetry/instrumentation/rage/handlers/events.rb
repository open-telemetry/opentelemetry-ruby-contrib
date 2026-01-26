# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/semconv/incubating/code'
require 'opentelemetry/semconv/incubating/messaging'

module OpenTelemetry
  module Instrumentation
    module Rage
      module Handlers
        # The class records the publishing of Rage events and wraps event subscribers in spans.
        class Events < ::Rage::Telemetry::Handler
          handle 'events.event.publish', with: :create_publisher_span
          handle 'events.subscriber.process', with: :create_subscriber_span

          # @param event [Object] the event being published
          def self.create_publisher_span(event:, &)
            current_span = OpenTelemetry::Trace.current_span
            return yield unless current_span.recording?

            kind = :producer
            attributes = {
              SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.events',
              SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE => 'send',
              SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => event.class.name
            }

            Rage::Instrumentation.instance.tracer.in_span("#{event.class} publish", kind:, attributes:, &)
          end

          # @param event [Object] the event being processed
          # @param subscriber [Rage::Events::Subscriber] the subscriber processing the event
          def self.create_subscriber_span(event:, subscriber:)
            # deferred subscribers will be wrapped into spans by the `Handlers::Deferred` handler
            return yield if subscriber.class.deferred?

            kind = :consumer
            attributes = {
              SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.events',
              SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE => 'process',
              SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => event.class.name,
              SemConv::Incubating::CODE::CODE_FUNCTION_NAME => "#{subscriber.class}#call"
            }

            Rage::Instrumentation.instance.tracer.in_span("#{subscriber.class} process", kind:, attributes:) do |span|
              result = yield

              if result.error?
                span.record_exception(result.exception)
                span.status = OpenTelemetry::Trace::Status.error
              end
            end
          end
        end
      end
    end
  end
end
