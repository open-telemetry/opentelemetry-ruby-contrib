# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RestClient
      # Helper methods for RestClient instrumentation
      module Helpers
        class << self
          def determine_span_name(attributes, http_method)
            template = attributes['url.template']
            template ? "#{http_method} #{template}" : http_method
          end
        end
      end
    end
  end
end
