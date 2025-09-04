# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Trilogy
      # The Instrumentation class contains logic to detect and install the Trilogy instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_client_#{patch_type}")
          configure_propagator(config)
        end

        present do
          defined?(::Trilogy)
        end

        compatible do
          Gem::Requirement.create('>= 2.3', '< 3.0').satisfied_by?(Gem::Version.new(::Trilogy::VERSION))
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :span_name, default: :statement_type, validate: %I[statement_type db_name db_operation_and_name]
        option :obfuscation_limit, default: 2000, validate: :integer
        option :propagator, default: nil, validate: :string

        attr_reader :propagator

        private

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
          require_relative 'patches/dup/client'
        end

        def require_dependencies_stable
          require_relative 'patches/stable/client'
        end

        def require_dependencies_old
          require_relative 'patches/old/client'
        end

        def patch_client
          ::Trilogy.prepend(Patches::Dup::Client)
        end

        def patch_client_stable
          ::Trilogy.prepend(Patches::Stable::Client)
        end

        def patch_client_old
          ::Trilogy.prepend(Patches::Old::Client)
        end

        def patch_client_dup
          ::Trilogy.prepend(Patches::Dup::Client)
        end

        def configure_propagator(config)
          propagator = config[:propagator]
          @propagator = case propagator
                        when 'vitess' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::Vitess')
                        when 'none', nil then nil
                        else
                          OpenTelemetry.logger.warn "The #{propagator} propagator is unknown and cannot be configured"
                        end
        end

        def fetch_propagator(name, class_name, gem_suffix = name)
          Kernel.const_get(class_name).sql_query_propagator
        rescue NameError
          OpenTelemetry.logger.warn "The #{name} propagator cannot be configured - please add opentelemetry-propagator-#{gem_suffix} to your Gemfile"
          nil
        end
      end
    end
  end
end
