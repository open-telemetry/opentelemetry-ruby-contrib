# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::MetricsTestHelpers do
  with_metrics_sdk do
    it 'must be defined' do
      _(!defined?(OpenTelemetry::SDK::Metrics).nil?).must_equal(true)
    end
  end

  without_metrics_sdk do
    it 'must not be defined' do
      _(!defined?(OpenTelemetry::SDK::Metrics).nil?).must_equal(false)
    end
  end
end
