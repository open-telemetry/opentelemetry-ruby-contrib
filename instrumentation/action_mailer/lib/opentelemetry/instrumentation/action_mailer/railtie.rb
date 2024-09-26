# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionMailer
      DELIVER_SUBSCRIPTION = 'deliver.action_mailer'
      PROCESS_SUBSCRIPTION = 'process.action_mailer'

      # This Railtie sets up subscriptions to relevant ActionMailer notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          config = ActionMailer::Instrumentation.instance.config

          ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
            ActionMailer::Instrumentation.instance.tracer,
            DELIVER_SUBSCRIPTION,
            config[:notification_payload_transform],
            config[:disallowed_notification_payload_keys]
          )

          ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
            ActionMailer::Instrumentation.instance.tracer,
            PROCESS_SUBSCRIPTION,
            config[:process_payload_transform],
            config[:disallowed_process_payload_keys]
          )
        end
      end
    end
  end
end
