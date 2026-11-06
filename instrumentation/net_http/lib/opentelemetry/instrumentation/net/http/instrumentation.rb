# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        # The Instrumentation class contains logic to detect and install the Net::HTTP
        # instrumentation
        class Instrumentation < OpenTelemetry::Instrumentation::Base
          install do |_config|
            patch_type = determine_semconv
            send(:"require_dependencies_#{patch_type}")
            send(:"patch_#{patch_type}")
          end

          present do
            defined?(::Net::HTTP)
          end

          ## Supported configuration keys for the install config hash:
          #
          # untraced_hosts: if a request's address matches any of the `String`
          #   or `Regexp` in this array, the instrumentation will not record a
          #   `kind = :client` representing the request and will not propagate
          #   context in the request.
          option :untraced_hosts, default: [], validate: :array

          # Bucket boundaries recommended by the stable HTTP semantic conventions
          CLIENT_REQUEST_DURATION_BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10].freeze

          # The `http.client.request.duration` histogram, only created when
          # the stable HTTP semantic conventions are in use.
          # @api private
          attr_reader :client_request_duration_histogram

          private

          def determine_semconv
            stability_opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', '')
            values = stability_opt_in.split(',').map(&:strip)

            if values.include?('http/dup')
              emit_old_semconv_deprecation_warning('http/dup')
              'dup'
            elsif values.include?('old')
              emit_old_semconv_deprecation_warning('old')
              'old'
            else
              'stable'
            end
          end

          def emit_old_semconv_deprecation_warning(option)
            OpenTelemetry.logger.warn("The `#{option}` option for OTEL_SEMCONV_STABILITY_OPT_IN is deprecated and will be removed on April 15, 2026. Please migrate to the stable HTTP semantic conventions.")
          end

          def require_dependencies_dup
            require_relative 'patches/dup/instrumentation'
          end

          def require_dependencies_old
            require_relative 'patches/old/instrumentation'
          end

          def require_dependencies_stable
            require_relative 'patches/stable/instrumentation'
          end

          def patch_dup
            ::Net::HTTP.prepend(Patches::Dup::Instrumentation)
          end

          def patch_old
            ::Net::HTTP.prepend(Patches::Old::Instrumentation)
          end

          def patch_stable
            @client_request_duration_histogram ||= meter.create_histogram(
              'http.client.request.duration',
              unit: 's',
              description: 'Duration of HTTP client requests.',
              advisory: { explicit_bucket_boundaries: CLIENT_REQUEST_DURATION_BUCKETS }
            )
            ::Net::HTTP.prepend(Patches::Stable::Instrumentation)
          end
        end
      end
    end
  end
end
