# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mongo
      # Instrumentation class that detects and installs the Mongo instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.5.0')
        MAX_VERSION = Gem::Version.new('2.22.0') # Mongo 2.23.0+ has native OpenTelemetry instrumentation

        install do |_config|
          require_dependencies
          register_subscriber
        end

        present do
          !defined?(::Mongo::Monitoring::Global).nil?
        end

        compatible do
          if gem_version < MINIMUM_VERSION
            false
          elsif gem_version > MAX_VERSION
            OpenTelemetry.logger.info("Mongo #{gem_version} has native OpenTelemetry support. Skipping community instrumentation.")
            false
          else
            true
          end
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit obfuscate include]

        attr_reader :semconv

        private

        def gem_version
          Gem::Version.new(::Mongo::VERSION)
        end

        def determine_semconv
          opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', nil)
          return :old if opt_in.nil?

          opt_in_values = opt_in.split(',').map(&:strip)

          if opt_in_values.include?('database/dup')
            :dup
          elsif opt_in_values.include?('database')
            :stable
          else
            :old
          end
        end

        def require_dependencies
          @semconv = determine_semconv

          case @semconv
          when :old
            require_relative 'subscribers/old/subscriber'
          when :stable
            require_relative 'subscribers/stable/subscriber'
          when :dup
            require_relative 'subscribers/dup/subscriber'
          end
        end

        def register_subscriber
          subscriber_class = case @semconv
                             when :stable
                               Subscribers::Stable::Subscriber
                             when :dup
                               Subscribers::Dup::Subscriber
                             else
                               Subscribers::Old::Subscriber
                             end
          # Subscribe to all COMMAND queries with our subscriber class
          ::Mongo::Monitoring::Global.subscribe(::Mongo::Monitoring::COMMAND, subscriber_class.new)
        end
      end
    end
  end
end
