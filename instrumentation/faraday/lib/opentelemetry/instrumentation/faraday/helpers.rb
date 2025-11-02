# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      # Helper methods for Faraday instrumentation
      module Helpers
        extend self

        def format_span_name(attributes, http_method)
          template = attributes['url.template']
          template ? "#{http_method} #{template}" : http_method
        end
      end
    end
  end
end
