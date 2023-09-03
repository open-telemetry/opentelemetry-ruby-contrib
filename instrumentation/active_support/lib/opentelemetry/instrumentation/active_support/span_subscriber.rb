# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # rubocop:disable Style/Documentation
    module ActiveSupport
      # The SpanSubscriber is a special ActiveSupport::Notification subscription
      # handler which turns notifications into generic spans, taking care to handle
      # context appropriately.

      # A very hacky way to make sure that OpenTelemetry::Instrumentation::ActiveSupport::SpanSubscriber
      # gets invoked first
      # Rails 6+ https://github.com/rails/rails/blob/0f0ec9908e25af36df2d937dc431f626a4102b3d/activesupport/lib/active_support/notifications/fanout.rb#L51
      def self.subscribe(
        tracer,
        pattern,
        notification_payload_transform = nil,
        disallowed_notification_payload_keys = []
      )
        subscriber = OpenTelemetry::Instrumentation::ActiveSupport::SpanSubscriber.new(
          name: pattern,
          tracer: tracer,
          notification_payload_transform: notification_payload_transform,
          disallowed_notification_payload_keys: disallowed_notification_payload_keys
        )

        subscriber_object = ::ActiveSupport::Notifications.subscribe(pattern, subscriber)

        ::ActiveSupport::Notifications.notifier.synchronize do
          subscribers = ::ActiveSupport::Notifications.notifier.instance_variable_get(:@string_subscribers)[pattern]

          if subscribers.nil?
            OpenTelemetry.handle_error(
              message: 'Unable to move OTEL ActiveSupport Notifications subscriber to the front of the notifications list which may cause incomplete traces.' \
                       'Please report an issue here: ' \
                       'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/new?labels=bug&template=bug_report.md&title=ActiveSupport%20Notifications%20subscribers%20list%20is%20nil'
            )
          else
            subscribers.unshift(
              subscribers.delete(subscriber_object)
            )
          end
        end
        subscriber_object
      end

      class SpanSubscriber
        ALWAYS_VALID_PAYLOAD_TYPES = [TrueClass, FalseClass, String, Numeric, Symbol].freeze

        def initialize(name:, tracer:, notification_payload_transform: nil, disallowed_notification_payload_keys: [])
          @span_name = name.split('.')[0..1].reverse.join(' ').freeze
          @tracer = tracer
          @notification_payload_transform = notification_payload_transform
          @disallowed_notification_payload_keys = disallowed_notification_payload_keys
        end

        def start(name, id, payload)
          span = @tracer.start_span(@span_name, kind: :internal)
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )
          payload.merge!(
            __opentelemetry_span: span,
            __opentelemetry_ctx_token: token
          )

          [span, token]
        end

        def finish(name, id, payload)
          span = payload.delete(:__opentelemetry_span)
          token = payload.delete(:__opentelemetry_ctx_token)
          return unless span && token

          attrs = transform_payload(payload).each_with_object({}) do |(k, v), accum|
            accum[k.to_s] = sanitized_value(v) if valid_payload_key?(k) && valid_payload_value?(v)
          end

          span.add_attributes(attrs)

          if (e = payload[:exception_object])
            span.record_exception(e)
            span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
          end

          span.finish
          OpenTelemetry::Context.detach(token)
        end

        private

        def transform_payload(payload)
          return payload if @notification_payload_transform.nil?

          @notification_payload_transform.call(payload)
        end

        def valid_payload_key?(key)
          %i[exception exception_object].none?(key) && @disallowed_notification_payload_keys.none?(key)
        end

        def valid_payload_value?(value)
          if value.is_a?(Array)
            return true if value.empty?

            value.map(&:class).uniq.size == 1 && ALWAYS_VALID_PAYLOAD_TYPES.any? { |t| value.first.is_a?(t) }
          else
            ALWAYS_VALID_PAYLOAD_TYPES.any? { |t| value.is_a?(t) }
          end
        end

        # We'll accept symbols as values, but stringify them; and we'll stringify symbols within an array.
        def sanitized_value(value)
          if value.is_a?(Array)
            value.map { |v| v.is_a?(Symbol) ? v.to_s : v }
          elsif value.is_a?(Symbol)
            value.to_s
          else
            value
          end
        end
      end
    end
  end
  # rubocop:enable Style/Documentation
end
