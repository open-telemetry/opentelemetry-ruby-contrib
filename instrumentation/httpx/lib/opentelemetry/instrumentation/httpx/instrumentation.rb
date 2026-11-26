# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      # The Instrumentation class contains logic to detect and install the Http instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          patch_type = determine_semconv
          send(:"require_dependencies_#{patch_type}")
          send(:"patch_#{patch_type}")
        end

        compatible do
          Gem::Version.new(::HTTPX::VERSION) >= Gem::Version.new('1.7.4')
        end

        present do
          defined?(::HTTPX)
        end

        option :peer_service, default: nil, validate: :string

        # Bucket boundaries recommended by the stable HTTP semantic conventions
        CLIENT_REQUEST_DURATION_BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10].freeze

        # The `http.client.request.duration` histogram, only created when
        # the stable HTTP semantic conventions are in use.
        # @api private
        attr_reader :client_request_duration_histogram

        # :nodoc:
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

        # :nodoc:
        def emit_old_semconv_deprecation_warning(option)
          OpenTelemetry.logger.warn("The `#{option}` option for OTEL_SEMCONV_STABILITY_OPT_IN is deprecated and will be removed on April 15, 2026. Please migrate to the stable HTTP semantic conventions.")
        end

        # :nodoc:
        def patch_old
          otel_session = ::HTTPX.plugin(Old::Plugin)

          ::HTTPX.send(:remove_const, :Session)
          ::HTTPX.send(:const_set, :Session, otel_session.class)
        end

        # :nodoc:
        def patch_stable
          otel_session = ::HTTPX.plugin(Stable::Plugin)
          @client_request_duration_histogram ||= meter.create_histogram(
            'http.client.request.duration',
            unit: 's',
            description: 'Duration of HTTP client requests.',
            advisory: { explicit_bucket_boundaries: CLIENT_REQUEST_DURATION_BUCKETS }
          )

          ::HTTPX.send(:remove_const, :Session)
          ::HTTPX.send(:const_set, :Session, otel_session.class)
        end

        # :nodoc:
        def patch_dup
          otel_session = ::HTTPX.plugin(Dup::Plugin)

          ::HTTPX.send(:remove_const, :Session)
          ::HTTPX.send(:const_set, :Session, otel_session.class)
        end

        # :nodoc:
        def require_dependencies_old
          require_relative 'old/plugin'
        end

        # :nodoc:
        def require_dependencies_stable
          require_relative 'stable/plugin'
        end

        # :nodoc:
        def require_dependencies_dup
          require_relative 'dup/plugin'
        end
      end
    end
  end
end
