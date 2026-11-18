# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        # Utility module for HTTP-related helper methods
        # @api private
        module HttpHelper # rubocop:disable Metrics/ModuleLength
          # Lightweight struct to hold span creation attributes
          SpanCreationAttributes = Struct.new(:span_name, :attributes)

          # Constant for the HTTP status range
          HTTP_STATUS_SUCCESS_RANGE = (100..399)

          # Returns the request path for strings and URI-like objects.
          # @param path [String, #request_uri] The request path
          # @return [String, nil] The normalized request path
          def self.request_path(path)
            path.respond_to?(:request_uri) ? path.request_uri : path
          end

          # Splits a request path into its path and query components.
          # @param path [String, #request_uri] The request path
          # @return [Array<String, String, nil>] The path and query components
          def self.split_path_and_query(path)
            path = request_path(path)
            return [nil, nil] unless path

            path_and_query = path.split('?')

            [path_and_query[0], path_and_query[1]]
          end

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

          private_constant :METHOD_CACHE

          OLD_SPAN_NAMES_BY_METHOD = METHOD_CACHE.values.uniq.to_h do |method|
            [method, "HTTP #{method}"]
          end.freeze

          private_constant :OLD_SPAN_NAMES_BY_METHOD

          # Prepares span data using old semantic conventions
          # @param method [String, Symbol] The HTTP method
          # @return [SpanCreationAttributes] struct containing span_name and attributes hash
          def self.span_attrs_for_old(method)
            client_context_attrs = OpenTelemetry::Common::HTTP::ClientContext.attributes
            normalized = METHOD_CACHE[method]
            attributes = client_context_attrs.dup

            # Determine base span name and method value
            if normalized
              span_name = OLD_SPAN_NAMES_BY_METHOD[normalized]
              method_value = normalized
            else
              span_name = 'HTTP'
              method_value = '_OTHER'
            end

            attributes['http.method'] ||= method_value

            SpanCreationAttributes.new(span_name: span_name, attributes: attributes)
          end

          # Prepares span data using stable semantic conventions
          # @param method [String, Symbol] The HTTP method
          # @return [SpanCreationAttributes] struct containing span_name and attributes hash
          def self.span_attrs_for_stable(method)
            client_context_attrs = OpenTelemetry::Common::HTTP::ClientContext.attributes
            url_template = client_context_attrs['url.template']
            normalized = METHOD_CACHE[method]
            attributes = client_context_attrs.dup

            # Determine base span name and method value
            if normalized
              base_name = normalized
              method_value = normalized
              original = nil
            else
              base_name = 'HTTP'
              method_value = '_OTHER'
              original = method.to_s
            end

            span_name = url_template ? "#{base_name} #{url_template}" : base_name
            attributes['http.request.method'] ||= method_value
            attributes['http.request.method_original'] ||= original if original

            SpanCreationAttributes.new(span_name: span_name, attributes: attributes)
          end

          # Prepares `http.client.request.duration` attributes using stable semantic conventions.
          # @param method [String] The normalized HTTP method
          # @param address [String, nil] The server address
          # @param port [Integer, nil] The server port
          # @param response [Net::HTTPResponse, nil] The response, if received
          # @param error_type [String, nil] The class name of a raised error, if any
          # @return [Hash] the metric attributes
          def self.metric_attrs(method, address, port, response, error_type)
            attributes = { 'http.request.method' => method, 'server.address' => address, 'server.port' => port }

            if response&.code
              status_code = response.code.to_i
              attributes['http.response.status_code'] = status_code
              attributes['network.protocol.version'] = response.http_version
              error_type ||= response.code unless HttpHelper::HTTP_STATUS_SUCCESS_RANGE.cover?(status_code)
            end
            attributes['error.type'] = error_type if error_type

            attributes.compact
          end

          # Prepares span data using both old and stable semantic conventions
          # @param method [String, Symbol] The HTTP method
          # @return [SpanCreationAttributes] struct containing span_name and attributes hash
          def self.span_attrs_for_dup(method)
            client_context_attrs = OpenTelemetry::Common::HTTP::ClientContext.attributes
            url_template = client_context_attrs['url.template']
            normalized = METHOD_CACHE[method]
            attributes = client_context_attrs.dup

            # Determine base span name and method value
            if normalized
              base_name = normalized
              method_value = normalized
              original = nil
            else
              base_name = 'HTTP'
              method_value = '_OTHER'
              original = method.to_s
            end

            span_name = url_template ? "#{base_name} #{url_template}" : base_name
            attributes['http.method'] ||= method_value
            attributes['http.request.method'] ||= method_value
            attributes['http.request.method_original'] ||= original if original

            SpanCreationAttributes.new(span_name: span_name, attributes: attributes)
          end
        end
      end
    end
  end
end
