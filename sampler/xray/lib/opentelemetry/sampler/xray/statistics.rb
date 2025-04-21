# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampler
    module XRay
      # Statistics contains metric counters for each sampling attempt in each Sampling Rule Applier
      class Statistics
        attr_accessor :request_count, :sample_count, :borrow_count

        def initialize(request_count: 0, sample_count: 0, borrow_count: 0)
          @request_count = request_count
          @sample_count = sample_count
          @borrow_count = borrow_count
        end

        def retrieve_statistics
          {
            request_count: @request_count,
            sample_count: @sample_count,
            borrow_count: @borrow_count
          }
        end

        def reset_statistics
          @request_count = 0
          @sample_count = 0
          @borrow_count = 0
        end
      end
    end
  end
end
