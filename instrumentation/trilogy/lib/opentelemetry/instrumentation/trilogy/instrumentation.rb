# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Trilogy
      # The {OpenTelemetry::Instrumentation::Trilogy::Instrumentation} class contains logic to detect and install the Trilogy instrumentation
      #
      # Installation and configuration of this instrumentation is done within the
      # {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry/SDK#configure-instance_method OpenTelemetry::SDK#configure}
      # block, calling {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use use()}
      # or {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use_all use_all()}.
      #
      # ## Configuration keys and options
      #
      # ### `:db_statement`
      #
      # Controls how SQL queries appear in spans.
      #
      # - `:obfuscate` **(default)** - Replaces literal values with `?` to prevent
      #   sensitive data from being recorded.
      # - `:include` - Records the raw SQL query as-is.
      # - `:omit` - Excludes the SQL query attribute entirely.
      #
      # ### `:obfuscation_limit`
      #
      # Maximum length of the obfuscated SQL statement. Statements exceeding this limit
      # are truncated. Default is `2000`.
      #
      # ### `:peer_service`
      #
      # Sets the `peer.service` attribute on spans. Default is `nil`.
      # Only applies when using old semantic conventions. Deprecated with no replacement. 
      #
      # ### `:propagator`
      #
      # Propagator for injecting trace context into SQL comments.
      #
      # - `'none'` **(default)** - Disables trace context propagation.
      # - `'tracecontext'` - Uses W3C Trace Context format via SQL comments.
      # - `'vitess'` - Uses Vitess-style propagation. Requires the
      #   `opentelemetry-propagator-vitess` gem.
      #
      # ### `:record_exception`
      #
      # Records exceptions as span events when an error occurs. Default is `true`.
      #
      # ### `:span_name`
      #
      # Controls how span names are generated. Only applies when using old semantic
      # conventions; ignored for stable semantic conventions.
      #
      # - `:statement_type` **(default)** - Uses the SQL operation (e.g., `SELECT`).
      # - `:db_name` - Uses the database name.
      # - `:db_operation_and_name` - Combines the operation and database name.
      #
      # @example An explicit default configuration
      #   OpenTelemetry::SDK.configure do |c|
      #     c.use_all({
      #       'OpenTelemetry::Instrumentation::Trilogy' => {
      #         db_statement: :obfuscate,
      #         obfuscation_limit: 2000,
      #         peer_service: nil,
      #         propagator: 'none',
      #         record_exception: true,
      #         span_name: :statement_type,
      #       },
      #     })
      #   end
      #
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
        option :propagator, default: 'none', validate: %w[none tracecontext vitess]
        option :record_exception, default: true, validate: :boolean

        attr_reader :propagator, :semconv

        private

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
            ::Trilogy.prepend(Patches::Old::Client)
          when :stable
            ::Trilogy.prepend(Patches::Stable::Client)
          when :dup
            ::Trilogy.prepend(Patches::Dup::Client)
          end
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
          OpenTelemetry.logger.warn "The #{name} propagator cannot be configured - please add opentelemetry-propagator-#{gem_suffix} to your Gemfile"
          nil
        end
      end
    end
  end
end
