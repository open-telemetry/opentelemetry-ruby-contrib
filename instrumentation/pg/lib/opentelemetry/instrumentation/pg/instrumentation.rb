# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module PG
      # The Instrumentation class contains logic to detect and install the Pg instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('1.1.0')

        install do |config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_client_#{patch_type}")
          configure_propagator(config)
        end

        present do
          defined?(::PG)
        end

        compatible do
          gem_version > Gem::Version.new(MINIMUM_VERSION)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :obfuscation_limit, default: 2000, validate: :integer
        option :propagator, default: 'none', validate: %w[none tracecontext]

        attr_reader :propagator

        private

        def gem_version
          Gem::Version.new(::PG::VERSION)
        end

        def determine_semconv
          stability_opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', '')
          values = stability_opt_in.split(',').map(&:strip)

          if values.include?('database/dup')
            'dup'
          elsif values.include?('database')
            'stable'
          else
            'old'
          end
        end

        def require_dependencies_dup
          require_relative 'patches/dup/connection'
        end

        def require_dependencies_old
          require_relative 'patches/old/connection'
        end

        def require_dependencies_stable
          require_relative 'patches/stable/connection'
        end

        def patch_client_dup
          ::PG::Connection.prepend(Patches::Dup::Connection)
          ::PG::Connection.singleton_class.prepend(Patches::Dup::Connect)
        end

        def patch_client_old
          ::PG::Connection.prepend(Patches::Old::Connection)
          ::PG::Connection.singleton_class.prepend(Patches::Old::Connect)
        end

        def patch_client_stable
          ::PG::Connection.prepend(Patches::Stable::Connection)
          ::PG::Connection.singleton_class.prepend(Patches::Stable::Connect)
        end

        def configure_propagator(config)
          propagator = config[:propagator]
          @propagator = case propagator
                        when 'tracecontext' then OpenTelemetry::Helpers::SqlProcessor::SqlCommenter.sql_query_propagator
                        when 'none', nil then nil
                        else
                          OpenTelemetry.logger.warn "The #{propagator} propagator is unknown and cannot be configured"
                        end
        end
      end
    end
  end
end
