# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      # Module for normalizing HTTP methods
      # @api private
      module HttpHelper
        # Lightweight struct to hold span creation attributes
        SpanCreationAttributes = Struct.new(:span_name, :normalized_method, :original_method, keyword_init: true)

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

        # Prepares all span data for the specified semantic convention in a single call
        # @param method [String, Symbol] The HTTP method
        # @param semconv [Symbol] The semantic convention to use (:stable or :old)
        # @return [SpanCreationAttributes] struct containing span_name, normalized_method, and original_method
        def self.span_attrs_for(method, semconv: :stable)
          normalized = METHOD_CACHE[method]
          if normalized
            span_name = semconv == :old ? OLD_SPAN_NAMES[normalized] : normalized
            SpanCreationAttributes.new(
              span_name: span_name,
              normalized_method: normalized,
              original_method: nil
            )
          else
            SpanCreationAttributes.new(
              span_name: 'HTTP',
              normalized_method: '_OTHER',
              original_method: method.to_s
            )
          end
        end
      end
    end
  end
end
