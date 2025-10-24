# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Excon gem
    module Excon
      def self.span_name(attrs)
        http_method = attrs['http.request.method'] || attrs['http.method']
        url_template = attrs['url.template']
        return "#{http_method} #{url_template}" if url_template && http_method
        return url_template if url_template
        return http_method if http_method

        return 'HTTP' # Fallback span name for cases where the HTTP method is _OTHER or unknown
      end
    end
  end
end

require_relative 'excon/instrumentation'
require_relative 'excon/version'
