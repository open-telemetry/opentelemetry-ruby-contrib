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
          require_dependencies
          patch_client
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

        def require_dependencies
          require_relative 'patches/client'
        end

        def patch_client
          ::Trilogy.prepend(Patches::Client)
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
