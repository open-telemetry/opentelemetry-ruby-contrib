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
        install do |_config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_client_#{patch_type}")
        end

        present do
          defined?(::Mysql2)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :span_name, default: :statement_type, validate: %I[statement_type db_name db_operation_and_name]
        option :obfuscation_limit, default: 2000, validate: :integer

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

        def require_dependencies_old
          require_relative 'patches/old/client'
        end

        def require_dependencies_stable
          require_relative 'patches/stable/client'
        end

        def patch_client_dup
          ::Mysql2::Client.prepend(Patches::Dup::Client)
        end

        def patch_client_old
          ::Mysql2::Client.prepend(Patches::Old::Client)
        end

        def patch_client_stable
          ::Mysql2::Client.prepend(Patches::Stable::Client)
        end
      end
    end
  end
end
