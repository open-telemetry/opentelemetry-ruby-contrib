# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      # The Instrumentation class contains logic to detect and install the LMDB instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::LMDB)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :include, validate: %I[omit include]

        attr_reader :semconv

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

        def patch
          case @semconv
          when :old
            ::LMDB::Environment.prepend(Patches::Old::Environment)
            ::LMDB::Database.prepend(Patches::Old::Database)
          when :stable
            ::LMDB::Environment.prepend(Patches::Stable::Environment)
            ::LMDB::Database.prepend(Patches::Stable::Database)
          when :dup
            ::LMDB::Environment.prepend(Patches::Dup::Environment)
            ::LMDB::Database.prepend(Patches::Dup::Database)
          end
        end

        def require_dependencies
          @semconv = determine_semconv

          case @semconv
          when :old
            require_relative 'patches/old/database'
            require_relative 'patches/old/environment'
          when :stable
            require_relative 'patches/stable/database'
            require_relative 'patches/stable/environment'
          when :dup
            require_relative 'patches/dup/database'
            require_relative 'patches/dup/environment'
          end
        end
      end
    end
  end
end
