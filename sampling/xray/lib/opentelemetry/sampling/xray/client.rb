# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Client
        # @param [String] endpoint
        def initialize(endpoint:)
          @endpoint = endpoint
        end

        # @return [Array<SamplingRule>]
        def fetch_sampling_rules
          raise(NotImplementedError)
        end
      end
    end
  end
end
