# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module FactoryBot
      # The Instrumentation class contains logic to detect and install the FactoryBot instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('4.0')

        install do |_config|
          require_dependencies
          add_subscriber
        end

        present do
          defined?(::FactoryBot)
        end

        compatible do
          !defined?(::ActiveSupport::Notifications).nil? && gem_version >= MINIMUM_VERSION
        end

        private

        def require_dependencies
          require_relative 'run_factory_subscriber'
        end

        def add_subscriber
          subscriber = RunFactorySubscriber.new
          ::ActiveSupport::Notifications.subscribe('factory_bot.run_factory', subscriber)
        end

        def gem_version
          if defined?(::FactoryBot::VERSION)
            Gem::Version.new(::FactoryBot::VERSION)
          else
            Gem::Version.new('0.0.0')
          end
        end
      end
    end
  end
end
