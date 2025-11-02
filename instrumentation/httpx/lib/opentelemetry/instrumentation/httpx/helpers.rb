# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      # Helper methods for HTTPX instrumentation
      module Helpers
        extend self

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
