# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      # Contains custom subscribers that implement the ActiveSupport::Notifications::Fanout::Subscribers::Evented
      # interface. Custom subscribers are needed to create a span at the start of an event, for example.
      #
      # Reference: https://github.com/rails/rails/blob/05cb63abdaf6101e6c8fb43119e2c0d08e543c28/activesupport/lib/active_support/notifications/fanout.rb#L320-L322
      module CustomSubscribers
        # Implements the ActiveSupport::Subscriber interface to instrument the start and finish of the endpoint_run event
        class EndpointRun
          # Runs at the start of the event that triggers the ActiveSupport::Notification
          def start(name, id, payload)
            EventHandler.endpoint_run_start(name, id, payload)
          end

          # Runs at the end of the event that triggers the ActiveSupport::Notification
          def finish(name, id, payload)
            EventHandler.endpoint_run_finish(name, id, payload)
          end
        end
      end
    end
  end
end
