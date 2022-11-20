# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      # The Instrumentation class contains logic to detect and install the ActionPack instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.2.0')

        install do |_config|
          require_railtie
          require_dependencies
          patch
          register_event_handler
        end

        present do
          defined?(::ActionController)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :enable_recognize_route, default: true, validate: :boolean
        option :span_naming, default: :rails_route, validate: %i[controller_action rails_route]

        private

        def gem_version
          ::ActionPack.version
        end

        def patch
          ::ActionController::Metal.prepend(Patches::ActionController::Metal)
        end

        def register_event_handler
          ActionControllerSubscriber.attach_to(:action_controller)
        end

        def require_dependencies
          require_relative 'patches/action_controller/metal'
          require_relative 'action_controller_subscriber'
        end

        def require_railtie
          require_relative 'railtie'
        end
      end
    end
  end
end
