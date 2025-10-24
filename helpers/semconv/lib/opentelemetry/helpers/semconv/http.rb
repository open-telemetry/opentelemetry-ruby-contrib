# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Helpers
    module Semconv
      # Provides HTTP semantic convention helpers for creating consistent span names per the specification
      # <https://opentelemetry.io/docs/specs/semconv/http/http-spans/#name>
      #
      # This module helps instrumentation libraries generate standardized span names
      # for HTTP operations according to OpenTelemetry semantic conventions. It handles
      # both current and legacy attribute formats and provides sensible fallbacks.
      #
      # ## Supported HTTP Methods
      #
      # The following standard HTTP methods are recognized and automatically normalized
      # to uppercase:
      # - CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE
      #
      # Methods can be provided in any case (lowercase, uppercase, mixed case) and will
      # be normalized appropriately. Non-standard methods fall back to the default "HTTP".
      #
      # ## Semantic Convention Support
      #
      # Supports both current and legacy OpenTelemetry semantic conventions:
      # - **Current**: `http.request.method`, `url.template`
      # - **Legacy**: `http.method` (deprecated but supported for compatibility)
      #
      # When both current and legacy attributes are present, current conventions take
      # precedence.
      #
      # @example Basic usage with method and URL template
      #   attrs = {
      #     'http.request.method' => 'GET',
      #     'url.template' => '/users/:id'
      #   }
      #   HTTP.name_from(attrs) # => "GET /users/:id"
      #
      # @example Method normalization
      #   attrs = { 'http.request.method' => 'get' }
      #   HTTP.name_from(attrs) # => "GET"
      #
      # @example Legacy attribute support
      #   attrs = { 'http.method' => 'POST' }
      #   HTTP.name_from(attrs) # => "POST"
      #
      # @example Preference for current conventions
      #   attrs = {
      #     'http.request.method' => 'PUT',
      #     'http.method' => 'GET'  # ignored in favor of current convention
      #   }
      #   HTTP.name_from(attrs) # => "PUT"
      #
      # @example Fallback behavior
      #   # Unknown method falls back to HTTP
      #   attrs = { 'http.request.method' => 'UNKNOWN' }
      #   HTTP.name_from(attrs) # => "HTTP"
      #
      #   # URL template without method
      #   attrs = { 'url.template' => '/health' }
      #   HTTP.name_from(attrs) # => "HTTP /health"
      #
      #   # Empty attributes
      #   HTTP.name_from({}) # => "HTTP"
      module HTTP
        # Mapping of HTTP methods (in various cases) to their uppercase equivalents.
        # Only includes standard HTTP methods as defined by RFC specifications.
        #
        # @api private
        HTTP_METHODS_TO_UPPERCASE = %w[connect delete get head options patch post put trace].each_with_object({}) do |method, hash|
          uppercase_method = method.upcase
          hash[method] = uppercase_method
          hash[method.to_sym] = uppercase_method
          hash[uppercase_method] = uppercase_method
        end.freeze

        module_function

        # Generates a span name from HTTP semantic convention attributes.
        #
        # Creates consistent span names for HTTP operations by combining the HTTP method
        # and URL template when available. Handles method normalization, attribute
        # precedence, and provides appropriate fallbacks.
        #
        # ## Attribute Processing
        #
        # 1. **Method Resolution**: Looks for `http.request.method` first, then falls back
        #    to `http.method` for legacy compatibility
        # 2. **Method Normalization**: Standard HTTP methods are converted to uppercase
        # 3. **Unknown Methods**: Non-standard methods default to "HTTP"
        # 4. **URL Template**: Uses `url.template` when available
        # 5. **Whitespace Handling**: Strips whitespace from all attribute values
        #
        # @param attrs [Hash] Hash of span attributes following OpenTelemetry semantic conventions
        # @return [String] The generated span name
        # - With method and template: `"GET /users/:id"`
        # - Method only: `"GET"`
        # - Template only: `"HTTP /health"`
        # - No attributes: `"HTTP"`
        def name_from(attrs)
          http_method = HTTP_METHODS_TO_UPPERCASE[attrs['http.request.method']&.strip || attrs['http.method']&.strip]
          http_method ||= 'HTTP'
          url_template = attrs['url.template']&.strip

          return "#{http_method} #{url_template}".strip if url_template && http_method

          http_method
        end
      end
    end
  end
end
