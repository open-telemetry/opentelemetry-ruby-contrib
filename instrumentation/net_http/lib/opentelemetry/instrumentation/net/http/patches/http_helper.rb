# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        module Patches
          # Utility module for HTTP-related helper methods
          module HttpHelper
            # Known HTTP methods per semantic conventions (stable methods only)
            # https://opentelemetry.io/docs/specs/semconv/http/http-spans/
            # Includes methods from RFC9110 and RFC5789 (PATCH)
            # Note: QUERY method is excluded as it's still in Development status
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
            ].freeze

            module_function

            # Normalizes an HTTP method per semantic conventions
            # @param method [String] the HTTP method to normalize
            # @return [Array<String, String|nil>] normalized method and original if different
            def normalize_method(method)
              method_str = method.to_s.upcase

              if KNOWN_METHODS.include?(method_str)
                [method_str, nil]
              else
                ['_OTHER', method_str]
              end
            end

            # Generates span name for stable semantic conventions
            # @param normalized_method [String] the normalized HTTP method
            # @return [String] the span name
            def span_name_for_stable(normalized_method)
              normalized_method == '_OTHER' ? 'HTTP' : normalized_method
            end

            # Generates span name for old semantic conventions
            # @param normalized_method [String] the normalized HTTP method
            # @return [String] the span name
            def span_name_for_old(normalized_method)
              normalized_method == '_OTHER' ? 'HTTP' : "HTTP #{normalized_method}"
            end
          end
        end
      end
    end
  end
end
