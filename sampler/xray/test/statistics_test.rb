# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::Statistics do
  it 'test_construct_statistics_and_retrieve_statistics' do
    statistics = OpenTelemetry::Sampler::XRay::Statistics.new(request_count: 12, sample_count: 3456, borrow_count: 7)

    assert_equal 12, statistics.instance_variable_get(:@request_count)
    assert_equal 3456, statistics.instance_variable_get(:@sample_count)
    assert_equal 7, statistics.instance_variable_get(:@borrow_count)

    obtained_statistics = statistics.retrieve_statistics
    assert_equal 12, obtained_statistics[:request_count]
    assert_equal 3456, obtained_statistics[:sample_count]
    assert_equal 7, obtained_statistics[:borrow_count]
  end
end
