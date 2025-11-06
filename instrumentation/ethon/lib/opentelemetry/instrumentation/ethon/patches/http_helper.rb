# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Ethon
      module Patches
        # Helper module for HTTP method normalization
        module HttpHelper
          KNOWN_METHODS = %w[CONNECT DELETE GET HEAD OPTIONS PATCH POST PUT TRACE].freeze

          def self.normalize_method(method)
            normalized = method.to_s.upcase
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
            normalized_method == '_OTHER' ? 'HTTP' : "HTTP #{normalized_method}"
          end
        end
      end
    end
  end
end
