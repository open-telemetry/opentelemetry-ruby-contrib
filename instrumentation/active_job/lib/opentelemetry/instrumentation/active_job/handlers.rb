# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'mappers/attribute'
require_relative 'handlers/default'
require_relative 'handlers/enqueue'
require_relative 'handlers/perform'

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      # Custom subscriber that handles ActiveJob notifications
      module Handlers
        module_function

        def install
          return unless Array(@subscriptions).empty?

          tracer = Instrumentation.instance.tracer
          mapper = Mappers::Attribute.new

          default_handler = Handlers::Default.new(tracer, mapper)
          enqueue_handler = Handlers::Enqueue.new(tracer, mapper)
          perform_handler = Handlers::Perform.new(tracer, mapper)

          # Why no perform_start?
          # This event causes much heartache as it is the first in a series of events that is triggered.
          # It should not be the ingress span because it does not measure anything.
          # https://github.com/rails/rails/blob/v6.1.7.6/activejob/lib/active_job/instrumentation.rb#L14
          # https://github.com/rails/rails/blob/v7.0.8/activejob/lib/active_job/instrumentation.rb#L19
          handlers_by_pattern = {
            'enqueue' => enqueue_handler,
            'enqueue_at' => enqueue_handler,
            'enqueue_retry' => default_handler,
            'perform' => perform_handler,
            'retry_stopped' => default_handler,
            'discard' => default_handler
          }

          @subscriptions = handlers_by_pattern.map do |key, handler|
            ActiveSupport::Notifications.subscribe("#{key}.active_job", handler)
          end
        end

        def uninstall
          @subscriptions&.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }
          @subscriptions = nil
        end
      end
    end
  end
end
