# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      module Middlewares
        # Utility module for HTTP-related helper methods
        module HttpHelper
          # Pre-computed mapping to avoid string allocations during normalization
          METHOD_CACHE = {
            'CONNECT' => 'CONNECT',
            'DELETE' => 'DELETE',
            'GET' => 'GET',
            'HEAD' => 'HEAD',
            'OPTIONS' => 'OPTIONS',
            'PATCH' => 'PATCH',
            'POST' => 'POST',
            'PUT' => 'PUT',
            'TRACE' => 'TRACE',
            'connect' => 'CONNECT',
            'delete' => 'DELETE',
            'get' => 'GET',
            'head' => 'HEAD',
            'options' => 'OPTIONS',
            'patch' => 'PATCH',
            'post' => 'POST',
            'put' => 'PUT',
            'trace' => 'TRACE',
            :connect => 'CONNECT',
            :delete => 'DELETE',
            :get => 'GET',
            :head => 'HEAD',
            :options => 'OPTIONS',
            :patch => 'PATCH',
            :post => 'POST',
            :put => 'PUT',
            :trace => 'TRACE'
          }.freeze

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

          private_constant :METHOD_CACHE, :OLD_SPAN_NAMES

          module_function

          # Normalizes an HTTP method according to OpenTelemetry semantic conventions
          # @param method [String, Symbol] The HTTP method to normalize
          # @return [Array<String, String|nil>] A tuple of [normalized_method, original_method]
          #   where normalized_method is either a known method or '_OTHER',
          #   and original_method is the original value if it was normalized to '_OTHER', or nil
          def normalize_method(method)
            normalized = METHOD_CACHE[method]
            return [normalized, nil] if normalized

            # Mixed case or unknown methods are treated as '_OTHER'
            ['_OTHER', method.to_s]
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
            OLD_SPAN_NAMES.fetch(normalized_method, 'HTTP')
          end
        end
      end
    end
  end
end
