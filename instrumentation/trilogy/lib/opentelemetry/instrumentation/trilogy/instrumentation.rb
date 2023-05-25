# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Trilogy
      # The Instrumentation class contains logic to detect and install the Trilogy instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Trilogy)
        end

        compatible do
          Gem::Requirement.create('>= 2.0', '< 3.0').satisfied_by?(Gem::Version.new(::Trilogy::VERSION))
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :span_name, default: :statement_type, validate: %I[statement_type db_name db_operation_and_name]
        option :obfuscation_limit, default: 2000, validate: :integer

        private

        def require_dependencies
          require_relative 'patches/client'
        end

        def patch_client
          ::Trilogy.prepend(Patches::Client)
        end
      end
    end
  end
end
