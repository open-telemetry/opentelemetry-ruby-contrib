# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'custom_subscribers/endpoint_run'
require_relative 'event_handler'

module OpenTelemetry
  module Instrumentation
    module Grape
      # Manages all subscriptions, both for custom subscribers and built-in notifications
      class Subscriber
        class << self
          # Subscribe to all custom and built-in notifications (except those specified in the :ignored_events configs)
          def subscribe
            subscribe_to_custom_notifications
            subscribe_to_built_in_notifications
          end

          private

          # ActiveSupport::Notifications that can be subscribed to using the documented `.subscribe` interface.
          #
          # Reference: https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html#method-c-subscribe
          SUBSCRIPTIONS = {
            endpoint_render: 'endpoint_render.grape',
            endpoint_run_filters: 'endpoint_run_filters.grape',
            format_response: 'format_response.grape'
          }.freeze

          # ActiveSupport::Notifications to be subscribed to that implement the ActiveSupport::Subscriber interface.
          #
          # Reference: https://github.com/rails/rails/blob/05cb63abdaf6101e6c8fb43119e2c0d08e543c28/activesupport/lib/active_support/notifications/fanout.rb#L320-L322
          CUSTOM_SUBSCRIPTIONS = {
            endpoint_run: OpenTelemetry::Instrumentation::Grape::CustomSubscribers::EndpointRun
          }.freeze

          def subscribe_to_custom_notifications
            CUSTOM_SUBSCRIPTIONS.each do |event, klass|
              ::ActiveSupport::Notifications.subscribe("#{event}.grape", klass.new)
            end
          end

          def subscribe_to_built_in_notifications
            subscriptions = filter_ignored_events(SUBSCRIPTIONS)
            subscriptions.each do |subscriber_method, event|
              ::ActiveSupport::Notifications.subscribe(event) do |*args|
                EventHandler.send(subscriber_method, *args)
              end
            end
          end

          def filter_ignored_events(subscriptions)
            subscriptions.reject { |event| config[:ignored_events].include?(event) }
          end

          def config
            Grape::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
