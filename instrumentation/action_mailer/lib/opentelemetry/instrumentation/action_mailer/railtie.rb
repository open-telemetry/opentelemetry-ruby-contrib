# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionMailer
      SUBSCRIPTIONS = %w[
        deliver.action_mailer
      ].freeze

      # This Railtie sets up subscriptions to relevant ActionMailer notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          SUBSCRIPTIONS.each do |subscription_name|
            config = ActionMailer::Instrumentation.instance.config
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActionMailer::Instrumentation.instance.tracer,
              subscription_name,
              config[:notification_payload_transform],
              config[:disallowed_notification_payload_keys]
            )
          end
        end
      end
    end
  end
end
