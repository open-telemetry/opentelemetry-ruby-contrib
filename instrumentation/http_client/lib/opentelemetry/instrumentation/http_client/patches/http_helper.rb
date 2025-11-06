# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        # Module for normalizing HTTP methods
        module HttpHelper
          # List of known HTTP methods per OpenTelemetry semantic conventions
          KNOWN_METHODS = %w[CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE].freeze

          # Normalizes an HTTP method according to OpenTelemetry semantic conventions
          # @param method [String, Symbol] The HTTP method to normalize
          # @return [Array<String, String|nil>] A tuple of [normalized_method, original_method]
          #   where normalized_method is either a known method or '_OTHER',
          #   and original_method is the uppercase original method if it was normalized to '_OTHER', or nil
          def self.normalize_method(method)
            normalized = method.to_s.upcase
            KNOWN_METHODS.include?(normalized) ? [normalized, nil] : ['_OTHER', normalized]
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
            normalized_method == '_OTHER' ? 'HTTP' : "HTTP #{normalized_method}"
          end
        end
      end
    end
  end
end
