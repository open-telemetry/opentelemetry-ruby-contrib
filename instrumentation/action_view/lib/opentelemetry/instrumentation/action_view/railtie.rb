# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionView
      SUBSCRIPTIONS = %w[
        render_template.action_view
        render_partial.action_view
        render_collection.action_view
        render_layout.action_view
      ].freeze

      # Maps Rails ActiveSupport notification payload keys to OpenTelemetry semantic convention attribute names
      PAYLOAD_KEY_MAPPING = {
        'identifier' => 'code.filepath',
        'layout' => 'view.layout.code.filepath',
        'count' => 'view.collection.count'
      }.freeze

      # Transforms ActionView notification payload keys to semantic convention names
      PAYLOAD_TRANSFORMER = lambda do |payload|
        payload.each_with_object({}) do |(key, value), transformed|
          semantic_key = PAYLOAD_KEY_MAPPING[key.to_s]
          transformed[semantic_key] = value if semantic_key
        end
      end

      # This Railtie sets up subscriptions to relevant ActionView notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          instance = ::OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance
          span_name_formatter = instance.config[:legacy_span_names] ? ::OpenTelemetry::Instrumentation::ActiveSupport::LEGACY_NAME_FORMATTER : nil

          # Use custom payload transformer if not overridden by user config
          payload_transform = instance.config[:notification_payload_transform] || PAYLOAD_TRANSFORMER

          SUBSCRIPTIONS.each do |subscription_name|
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              instance.tracer,
              subscription_name,
              payload_transform,
              instance.config[:disallowed_notification_payload_keys],
              span_name_formatter: span_name_formatter
            )
          end
        end
      end
    end
  end
end
