# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::FallbackSampler do
  # TODO: Add tests for Fallback sampler when Rate Limiter is implemented

  it 'test_to_string' do
    assert_equal(
      'FallbackSampler{fallback sampling with sampling config of 1 req/sec and 5% of additional requests}',
      OpenTelemetry::Sampler::XRay::FallbackSampler.new.description
    )
  end
end
