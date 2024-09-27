# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Instrumentation class that detects and installs the AwsSdk instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.0.0')

        install do |_config|
          require_dependencies
          patch if telemetry_plugin?
          add_plugins(Seahorse::Client::Base, *loaded_service_clients)
        end

        present do
          !defined?(::Seahorse::Client::Base).nil?
        end

        compatible do
          !gem_version.nil? && gem_version >= MINIMUM_VERSION
        end

        option :inject_messaging_context, default: false, validate: :boolean
        option :suppress_internal_instrumentation, default: false, validate: :boolean

        def gem_version
          if Gem.loaded_specs['aws-sdk']
            Gem.loaded_specs['aws-sdk'].version
          elsif Gem.loaded_specs['aws-sdk-core']
            Gem.loaded_specs['aws-sdk-core'].version
          elsif defined?(::Aws::CORE_GEM_VERSION)
            Gem::Version.new(::Aws::CORE_GEM_VERSION)
          end
        end

        private

        def require_dependencies
          require_relative 'handler'
          require_relative 'message_attributes'
          require_relative 'messaging_helper'
          require_relative 'patches/telemetry'
        end

        def add_plugins(*targets)
          targets.each do |klass|
            if telemetry_plugin?
              klass.add_plugin(AwsSdk::Plugin) unless klass.plugins.include?(Aws::Plugins::Telemetry)
            else
              klass.add_plugin(AwsSdk::Plugin)
            end
          end
        end

        def telemetry_plugin?
          ::Aws.const_defined?('Plugins::Telemetry')
        end

        def patch
          ::Aws::Plugins::Telemetry::Handler.prepend(Patches::Handler)
        end

        def loaded_service_clients
          ::Aws.constants.each_with_object([]) do |c, constants|
            m = ::Aws.const_get(c)
            next unless loaded_service?(c, m)

            begin
              constants << m.const_get(:Client)
            rescue StandardError => e
              OpenTelemetry.logger.warn("Constant could not be loaded: #{e}")
            end
          end
        end

        # This check does the following:
        # 1 - Checks if the service client is autoload or not
        # 2 - Validates whether if is a service client
        # note that Seahorse::Client::Base is a superclass for V3 clients
        # but for V2, it is Aws::Client
        def loaded_service?(constant, service_module)
          !::Aws.autoload?(constant) &&
            service_module.is_a?(Module) &&
            service_module.const_defined?(:Client) &&
            (service_module.const_get(:Client).superclass == Seahorse::Client::Base ||
              service_module.const_get(:Client).superclass == Aws::Client)
        end
      end
    end
  end
end
