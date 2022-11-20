# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      # ActiveSupport::Notification handlers for ActionController published events
      # https://guides.rubyonrails.org/active_support_instrumentation.html#action-controller
      class ActionControllerSubscriber < ::ActiveSupport::Subscriber
        # @private
        GTE_TO_RAILS_SIX = Gem::Version.new(::Rails.version) >= Gem::Version.new('6')

        def process_action(event)
          current_span = OpenTelemetry::Trace.current_span
          return unless current_span.recording?

          attributes = {}
          add_common_attributes(attributes, event)
          add_process_action_attributes(attributes, event.payload)

          current_span.add_attributes(attributes) unless attributes.empty?
        end

        protected

        def add_common_attributes(attributes, event)
          return unless GTE_TO_RAILS_SIX

          attach('process.runtime.ruby.allocations.count', event.try(:allocations), attributes)
          attach('rails.cpu.duration', event.try(:cpu_time).round(2), attributes)
        end

        def add_process_action_attributes(attributes, payload)
          attach('rails.view.duration', payload[:view_runtime]&.round(2), attributes)
          attach('rails.db.duration', payload[:db_runtime]&.round(2), attributes)
        end

        def attach(name, value, attributes)
          attributes[name] = value if value
        end
      end
    end
  end
end
