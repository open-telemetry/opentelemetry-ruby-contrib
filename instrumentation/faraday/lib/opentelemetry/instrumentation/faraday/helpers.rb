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

        # Known HTTP methods as defined in RFC9110, RFC5789, and httpbis-safe-method-w-body
        KNOWN_METHODS = %w[
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

        private_constant :KNOWN_METHODS

        # Normalizes an HTTP method to match OpenTelemetry semantic conventions.
        #
        # @param method [String, Symbol] The HTTP method to normalize
        # @return [String] The normalized method name (uppercase if known, '_OTHER' if unknown)
        # @api private
        def normalize_method(method)
          return '_OTHER' if method.nil? || method.to_s.empty?

          normalized = method.to_s.upcase
          KNOWN_METHODS.include?(normalized) ? normalized : '_OTHER'
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
