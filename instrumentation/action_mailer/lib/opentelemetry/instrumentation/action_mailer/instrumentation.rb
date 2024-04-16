# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionMailer
      # The Instrumentation class contains logic to detect and install the ActionMailer instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('6.1.0')
        install do |_config|
          resolve_email_address
          ecs_mail_convention
          require_dependencies
        end

        present do
          defined?(::ActionMailer)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :disallowed_notification_payload_keys, default: [], validate: :array
        option :notification_payload_transform,       default: nil, validate: :callable
        option :email_address,                        default: :omit, validate: %I[omit include]

        private

        def gem_version
          ::ActionMailer.version
        end

        def resolve_email_address
          return unless ActionMailer::Instrumentation.instance.config[:email_address] == :omit

          ActionMailer::Instrumentation.instance.config[:disallowed_notification_payload_keys] += ['email.to.address', 'email.from.address', 'email.cc.address', 'email.bcc.address']
        end

        def ecs_mail_convention
          if ActionMailer::Instrumentation.instance.config[:notification_payload_transform].nil?
            transform_attributes = lambda do |payload|
              transform_payload(payload)
            end
          else
            original_callable = ActionMailer::Instrumentation.instance.config[:notification_payload_transform]
            transform_attributes = lambda do |payload|
              original_callable.call(payload)
              transform_payload(payload)
            end
          end
          ActionMailer::Instrumentation.instance.config[:notification_payload_transform] = transform_attributes
        end

        # email attribute key convention is obtained from: https://www.elastic.co/guide/en/ecs/8.11/ecs-email.html
        def transform_payload(payload)
          payload['email.message_id'] = payload[:message_id]
          payload['email.subject']    = payload[:subject]
          payload['email.x_mailer']   = payload[:mailer]
          payload['email.to.address'] = payload[:to]
          payload['email.from.address'] = payload[:from]
          payload['email.cc.address'] = payload[:cc]
          payload['email.bcc.address'] = payload[:bcc]
          payload['email.delivery_timestamp'] = payload[:date]
          payload['email.origination_timestamp'] = payload[:date]

          payload.delete_if { |item| item.instance_of?(Symbol) }
        end

        def require_dependencies
          require_relative 'railtie'
        end
      end
    end
  end
end
