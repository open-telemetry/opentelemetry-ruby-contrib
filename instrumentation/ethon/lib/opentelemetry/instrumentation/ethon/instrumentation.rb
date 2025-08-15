# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Ethon
      # The Instrumentation class contains logic to detect and install the Ethon
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"add_patches_#{patch_type}")
        end

        present do
          defined?(::Ethon::Easy)
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
          require_relative 'patches/dup/easy'
          require_relative 'patches/multi'
        end

        def require_dependencies_stable
          require_relative 'patches/stable/easy'
          require_relative 'patches/multi'
        end

        def require_dependencies_old
          require_relative 'patches/old/easy'
          require_relative 'patches/multi'
        end

        def add_patches_dup
          ::Ethon::Easy.prepend(Patches::Dup::Easy)
          ::Ethon::Multi.prepend(Patches::Multi)
        end

        def add_patches_stable
          ::Ethon::Easy.prepend(Patches::Stable::Easy)
          ::Ethon::Multi.prepend(Patches::Multi)
        end

        def add_patches_old
          ::Ethon::Easy.prepend(Patches::Old::Easy)
          ::Ethon::Multi.prepend(Patches::Multi)
        end
      end
    end
  end
end
