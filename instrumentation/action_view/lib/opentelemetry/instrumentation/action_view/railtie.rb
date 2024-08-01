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

      # This Railtie sets up subscriptions to relevant ActionView notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          otel_config = ::OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance.config
          span_name_formatter = otel_config[:legacy_span_names] ? ::OpenTelemetry::Instrumentation::ActiveSupport::LEGACY_NAME_FORMATTER : nil

          SUBSCRIPTIONS.each do |subscription_name|
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ::OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance.tracer,
              subscription_name,
              otel_config[:notification_payload_transform],
              otel_config[:disallowed_notification_payload_keys],
              span_name_formatter: span_name_formatter
            )
          end
        end
      end
    end
  end
end
