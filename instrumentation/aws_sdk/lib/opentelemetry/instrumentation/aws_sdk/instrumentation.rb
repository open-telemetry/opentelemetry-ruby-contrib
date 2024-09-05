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
        CURRENT_MAJOR_VERSION = Gem::Version.new('3.0.0')

        install do |_config|
          require_dependencies
          add_plugins(Seahorse::Client::Base, *loaded_constants)
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
          require_relative 'services'
          require_relative 'message_attributes'
          require_relative 'messaging_helper'
        end

        def add_plugins(*targets)
          targets.each { |klass| klass.add_plugin(AwsSdk::Plugin) }
        end

        def loaded_constants
          if gem_version >= CURRENT_MAJOR_VERSION
            load_v3_constants
          else
            load_legacy_constants
          end
        end

        def load_v3_constants
          ::Aws.constants.each_with_object([]) do |c, constants|
            m = ::Aws.const_get(c)
            next unless unloaded_service?(c, m)

            begin
              constants << m.const_get(:Client)
            rescue StandardError => e
              OpenTelemetry.logger.warn("Constant could not be loaded: #{e}")
            end
          end
        end

        def unloaded_service?(constant, service_module)
          !::Aws.autoload?(constant) &&
            service_module.is_a?(Module) &&
            service_module.const_defined?(:Client) &&
            (service_module.const_get(:Client).superclass == Seahorse::Client::Base)
        end

        def load_legacy_constants
          # Cross-check services against loaded AWS constants
          # Module#const_get can return a constant from ancestors when there's a miss.
          # If this coincidentally matches another constant, it will attempt to patch
          # the wrong constant, resulting in patch failure.
          available_services = ::Aws.constants & SERVICES.map(&:to_sym)
          available_services.each_with_object([]) do |service, constants|
            next if ::Aws.autoload?(service)

            begin
              constants << ::Aws.const_get(service, false).const_get(:Client, false)
            rescue StandardError => e
              OpenTelemetry.logger.warn("Constant could not be loaded: #{e}")
            end
          end
        end
      end
    end
  end
end
