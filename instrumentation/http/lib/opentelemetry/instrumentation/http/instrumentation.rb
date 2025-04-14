# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      # The Instrumentation class contains logic to detect and install the Http instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          !(defined?(::HTTP::Client).nil? || defined?(::HTTP::Connection).nil?)
        end

        option :span_name_formatter, default: nil, validate: :callable

        def patch
          case ENV['OTEL_SEMCONV_STABILITY_OPT_IN']
          when 'http'
            patch_stable_semconv
          when 'http/dup'
            patch_dupe_semconv
          else
            patch_old_semconv
          end
        end

        def patch_old_semconv
          ::HTTP::Client.prepend(Patches::Client::Old)
          ::HTTP::Connection.prepend(Patches::Connection::Old)
        end

        def patch_dupe_semconv
          ::HTTP::Client.prepend(Patches::Client::Dupe)
          ::HTTP::Connection.prepend(Patches::Connection::Dupe)
        end

        def patch_stable_semconv
          ::HTTP::Client.prepend(Patches::Client::Stable)
          ::HTTP::Connection.prepend(Patches::Connection::Stable)
        end

        def require_dependencies
          require_relative 'patches/dupe_semconv_client'
          require_relative 'patches/dupe_semconv_connection'
          require_relative 'patches/old_semconv_client'
          require_relative 'patches/old_semconv_connection'
          require_relative 'patches/stable_semconv_client'
          require_relative 'patches/stable_semconv_connection'
        end
      end
    end
  end
end
