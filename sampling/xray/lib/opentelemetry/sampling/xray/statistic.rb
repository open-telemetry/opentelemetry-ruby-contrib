# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      attr_reader(:request_count)

      class Statistic
        def initialize
          @borrowed_count = 0
          @request_count = 0
          @sampled_count = 0
        end

        def increment_borrowed_count
          @borrowed_count += 1
        end

        def increment_request_count
          @request_count += 1
        end

        def increment_sampled_count
          @sampled_count += 1
        end
      end
    end
  end
end
