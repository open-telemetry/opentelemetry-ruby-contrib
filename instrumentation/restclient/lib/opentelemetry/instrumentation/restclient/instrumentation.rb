# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RestClient
      # The Instrumentation class contains logic to detect and install the RestClient
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_request_#{patch_type}")
        end

        present do
          defined?(::RestClient)
        end

        option :peer_service, default: nil, validate: :string

        private

        def determine_semconv
          stability_opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', '')
          values = stability_opt_in.split(',').map(&:strip)

          if values.include?('http/dup')
            'dup'
          elsif values.include?('http')
            'stable'
          else
            'old'
          end
        end

        def require_dependencies_dup
          require_relative 'patches/dup/request'
        end

        def require_dependencies_stable
          require_relative 'patches/stable/request'
        end

        def require_dependencies_old
          require_relative 'patches/old/request'
        end

        def patch_request_dup
          ::RestClient::Request.prepend(Patches::Dup::Request)
        end

        def patch_request_stable
          ::RestClient::Request.prepend(Patches::Stable::Request)
        end

        def patch_request_old
          ::RestClient::Request.prepend(Patches::Old::Request)
        end
      end
    end
  end
end
