# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'handlers/sql_handler'

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      # Module that contains custom event handlers for ActiveRecord notifications
      module Handlers
        module_function

        # Subscribes Event Handlers to relevant ActiveRecord notifications
        #
        # The following events are recorded as spans:
        # - sql.active_record
        #
        # @note this method is not thread safe and should not be used in a multi-threaded context
        def subscribe
          return unless Array(@subscriptions).empty?

          config = ActiveRecord::Instrumentation.instance.config
          return unless config[:enable_notifications_instrumentation]

          sql_handler = Handlers::SqlHandler.new

          @subscriptions = [
            ::ActiveSupport::Notifications.subscribe('sql.active_record', sql_handler)
          ]
        end

        # Removes Event Handler Subscriptions for ActiveRecord notifications
        # @note this method is not thread-safe and should not be used in a multi-threaded context
        def unsubscribe
          @subscriptions&.each { |subscriber| ::ActiveSupport::Notifications.unsubscribe(subscriber) }
          @subscriptions = nil
        end
      end
    end
  end
end
