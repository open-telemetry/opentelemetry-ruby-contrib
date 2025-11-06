# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Excon
      module Middlewares
        # Utility module for HTTP-related helper methods
        module HttpHelper
          # Standard HTTP methods as defined in the OpenTelemetry semantic conventions
          # https://opentelemetry.io/docs/specs/semconv/http/http-spans/
          KNOWN_METHODS = %w[CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE].freeze

          # Pre-computed span names for old semantic conventions to avoid allocations
          OLD_SPAN_NAMES = {
            'CONNECT' => 'HTTP CONNECT',
            'DELETE' => 'HTTP DELETE',
            'GET' => 'HTTP GET',
            'HEAD' => 'HTTP HEAD',
            'OPTIONS' => 'HTTP OPTIONS',
            'PATCH' => 'HTTP PATCH',
            'POST' => 'HTTP POST',
            'PUT' => 'HTTP PUT',
            'TRACE' => 'HTTP TRACE'
          }.freeze

          # Normalizes an HTTP method according to OpenTelemetry semantic conventions
          # @param method [String, Symbol] The HTTP method to normalize
          # @return [Array<String, String|nil>] A tuple of [normalized_method, original_method]
          #   - For known methods: returns [uppercase_method, nil]
          #   - For unknown methods: returns ['_OTHER', uppercase_original_method]
          def self.normalize_method(method)
            return [nil, nil] if method.nil?

            normalized = method.is_a?(String) ? method.upcase : method.to_s.upcase
            if KNOWN_METHODS.include?(normalized)
              [normalized, nil]
            else
              ['_OTHER', normalized]
            end
          end

          # Generates span name for stable semantic conventions
          # @param normalized_method [String] the normalized HTTP method
          # @return [String] the span name
          def self.span_name_for_stable(normalized_method)
            normalized_method == '_OTHER' ? 'HTTP' : normalized_method
          end

          # Generates span name for old semantic conventions
          # @param normalized_method [String] the normalized HTTP method
          # @return [String] the span name
          def self.span_name_for_old(normalized_method)
            OLD_SPAN_NAMES.fetch(normalized_method, 'HTTP')
          end
        end
      end
    end
  end
end
