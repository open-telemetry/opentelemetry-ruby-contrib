# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      # The Instrumentation class contains logic to detect and install the Grape instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('1.1.0')

        install do |_config|
          require_dependencies
        end

        present do
          defined?(::Grape)
        end

        compatible do
          # ActiveSupport::Notifications were introduced in Grape 0.13.0
          # https://github.com/ruby-grape/grape/blob/master/CHANGELOG.md#0130-2015810
          gem_version >= MINIMUM_VERSION
        end

        # Config options available in ddog Grape instrumentation
        option :enabled, default: true, validate: :boolean
        option :error_statuses, default: [], validate: :array
        # Config options necessary for OpenTelemetry::Instrumentation::ActiveSupport.subscribe called in railtie
        # instrumentation/active_support/lib/opentelemetry/instrumentation/active_support/span_subscriber.rb#L23
        # Used to validate if any of the payload keys are invalid
        option :disallowed_notification_payload_keys, default: [], validate: :array

        private

        def gem_version
          Gem::Version.new(::Grape::VERSION)
        end

        def require_dependencies
          # TODO: Include instrumentation dependencies
        end
      end
    end
  end
end
