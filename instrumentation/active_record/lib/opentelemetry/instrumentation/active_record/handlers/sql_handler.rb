# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Handlers
        # SqlHandler handles sql.active_record ActiveSupport notifications
        class SqlHandler
          # Invoked by ActiveSupport::Notifications at the start of the instrumentation block
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing SQL execution information
          # @return [Hash] the payload passed as a method argument
          def start(name, id, payload)
            span = tracer.start_span(
              payload[:name] || 'SQL',
              kind: :internal
            )
            token = OpenTelemetry::Context.attach(
              OpenTelemetry::Trace.context_with_span(span)
            )
            payload[:__opentelemetry_span] = span
            payload[:__opentelemetry_ctx_token] = token
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Invoked by ActiveSupport::Notifications at the end of the instrumentation block
          #
          # @param name [String] of the Event
          # @param id [String] of the event
          # @param payload [Hash] containing SQL execution information
          def finish(name, id, payload)
            attributes = {
              'db.active_record.async' => payload[:async] == true,
              'db.active_record.cached' => payload[:cached] == true
            }
            span = payload.delete(:__opentelemetry_span)
            span&.add_attributes(attributes)

            token = payload.delete(:__opentelemetry_ctx_token)
            return unless span && token

            if (e = payload[:exception_object])
              span.record_exception(e)
              span.status = OpenTelemetry::Trace::Status.error('Unhandled exception')
            end

            span.finish
            OpenTelemetry::Context.detach(token)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          private

          def tracer
            OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
