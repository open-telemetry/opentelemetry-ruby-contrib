# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mysql2
      # The Instrumentation class contains logic to detect and install the Mysql2
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          require_dependencies
          patch_client
          configure_propagator(config)
        end

        present do
          defined?(::Mysql2)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :span_name, default: :statement_type, validate: %I[statement_type db_name db_operation_and_name]
        option :obfuscation_limit, default: 2000, validate: :integer
        option :propagator, default: 'none', validate: %w[none tracecontext vitess]

        attr_reader :propagator, :semconv

        private

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
            require_relative 'patches/old/client'
          when :stable
            require_relative 'patches/stable/client'
          when :dup
            require_relative 'patches/dup/client'
          end
        end

        def patch_client
          case @semconv
          when :old
            ::Mysql2::Client.prepend(Patches::Old::Client)
          when :stable
            ::Mysql2::Client.prepend(Patches::Stable::Client)
          when :dup
            ::Mysql2::Client.prepend(Patches::Dup::Client)
          end
        end

        def configure_propagator(config)
          propagator = config[:propagator]
          @propagator = case propagator
                        when 'tracecontext' then OpenTelemetry::Helpers::SqlProcessor::SqlCommenter.sql_query_propagator
                        when 'vitess' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::Vitess')
                        when 'none', nil then nil
                        else
                          OpenTelemetry.logger.warn "The #{propagator} propagator is unknown and cannot be configured"
                        end
        end

        def fetch_propagator(name, class_name, gem_suffix = name)
          Kernel.const_get(class_name).sql_query_propagator
        rescue NameError
          OpenTelemetry.logger.warn "The #{name} propagator cannot be configured - please add opentelemetry-helpers-#{gem_suffix} to your Gemfile"
          nil
        end
      end
    end
  end
end
