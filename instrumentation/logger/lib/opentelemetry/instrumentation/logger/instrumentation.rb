# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      # The `OpenTelemetry::Instrumentation::Logger::Instrumentation` class contains logic to detect and install the
      # Ruby Logger library instrumentation.
      #
      # Installation and configuration of this instrumentation is done within the
      # {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry/SDK#configure-instance_method OpenTelemetry::SDK#configure}
      # block, calling {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use use()}
      # or {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use_all use_all()}.
      #
      # ## Configuration keys and options
      #
      # ### `:name`
      #
      # Sets the name of the OpenTelemetry Logger InstrumentationScope.
      #
      # - The name of this gem, `'opentelemetry-instrumentation-logger'` is the default.
      #
      # ### `:version`
      #
      # Sets the version of the OpenTelemetry Logger InstrumentationScope.
      #
      # - This gem's current version is the default.
      #
      #
      # @example An explicit default configuration
      #   OpenTelemetry::SDK.configure do |c|
      #     c.use_all({
      #       'OpenTelemetry::Instrumentation::Sidekiq' => {
      #         name: 'opentelemetry-instrumentation-logger',
      #         version: '0.1.0'
      #       },
      #     })
      #   end
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Logger) && defined?(::OpenTelemetry::SDK::Logs)
        end

        option :name, default: OpenTelemetry::Instrumentation::Logger::NAME, validate: :string
        option :version, default: OpenTelemetry::Instrumentation::Logger::VERSION, validate: :string

        private

        def patch
          ::Logger.prepend(Patches::Logger)
          active_support_patch
        end

        def require_dependencies
          require_relative 'patches/logger'
        end

        def active_support_patch
          return unless defined?(::ActiveSupport::Logger)

          require_relative 'patches/active_support_logger'
          ::ActiveSupport::Logger.singleton_class.prepend(Patches::ActiveSupportLogger)
        end
      end
    end
  end
end
