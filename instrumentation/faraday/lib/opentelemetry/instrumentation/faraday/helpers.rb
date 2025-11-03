# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      # Helper methods for Faraday instrumentation
      module Helpers
        extend self

        # HTTP status code range for successful responses
        HTTP_STATUS_SUCCESS_RANGE = (100..399)

        # Default known HTTP methods as defined in RFC9110, RFC5789, and httpbis-safe-method-w-body
        DEFAULT_KNOWN_METHODS = %w[
          CONNECT
          DELETE
          GET
          HEAD
          OPTIONS
          PATCH
          POST
          PUT
          TRACE
          QUERY
        ].freeze

        private_constant :DEFAULT_KNOWN_METHODS

        # Returns the list of known HTTP methods, checking the environment variable first
        #
        # @return [Array<String>] List of known HTTP methods in uppercase
        # @api private
        def known_methods
          @known_methods ||= if (env_methods = ENV.fetch('OTEL_INSTRUMENTATION_HTTP_KNOWN_METHODS', nil))
                               env_methods.split(',').map { |v| v.strip.upcase }.freeze
                             else
                               DEFAULT_KNOWN_METHODS
                             end
        end

        # Normalizes an HTTP method to match OpenTelemetry semantic conventions.
        # Returns both the normalized method and the original if they differ.
        #
        # @param method [String, Symbol] The HTTP method to normalize
        # @return [Array<String, String|nil>] A tuple of [normalized_method, original_method]
        #   where original_method is nil if it matches the normalized method
        # @api private
        def normalize_method(method)
          return ['_OTHER', nil] if method.nil? || method.to_s.empty?

          original = method.to_s
          normalized = original.upcase

          if known_methods.include?(normalized)
            # Return original as nil if it already matches the normalized form
            [normalized, (original == normalized ? nil : original)]
          else
            ['_OTHER', original]
          end
        end

        # Formats the span name based on the HTTP method and URL template if available
        #
        # @param attributes [Hash] The span attributes hash
        # @param http_method [String] The HTTP request method (e.g., 'GET', 'POST')
        # @return [String] The formatted span name
        # @api private
        def format_span_name(attributes, http_method)
          template = attributes['url.template']
          template ? "#{http_method} #{template}" : http_method
        end
      end
    end
  end
end
