# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampling::Hierarchical::Sampler do
  describe '#should_sample?' do
    it 'returns DROP if it has no samplers' do
      sampler = OpenTelemetry::Sampling::Hierarchical::Sampler.new

      _(
        sampler.should_sample?(
          trace_id: SecureRandom.uuid.to_s,
          parent_context: nil,
          links: [],
          name: SecureRandom.uuid.to_s,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal false
    end

    it 'returns RECORD_AND_SAMPLE if the first sampler returns RECORD_AND_SAMPLE' do
      trace_id = SecureRandom.uuid.to_s
      name = SecureRandom.uuid.to_s

      first_sampler = Minitest::Mock.new
      second_sampler = Minitest::Mock.new

      first_sampler.expect(
        :should_sample?,
        OpenTelemetry::SDK::Trace::Samplers::Result.new(
          decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE,
          tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
        ),
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )

      sampler = OpenTelemetry::Sampling::Hierarchical::Sampler.new first_sampler, second_sampler
      _(
        sampler.should_sample?(
          trace_id: trace_id,
          parent_context: nil,
          links: [],
          name: name,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal true

      first_sampler.verify
      second_sampler.verify
    end

    it 'returns RECORD_AND_SAMPLE if the second sampler returns RECORD_AND_SAMPLE' do
      trace_id = SecureRandom.uuid.to_s
      name = SecureRandom.uuid.to_s

      first_sampler = Minitest::Mock.new
      second_sampler = Minitest::Mock.new

      first_sampler.expect(
        :should_sample?,
        OpenTelemetry::SDK::Trace::Samplers::Result.new(
          decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
          tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
        ),
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )
      second_sampler.expect(
        :should_sample?,
        OpenTelemetry::SDK::Trace::Samplers::Result.new(
          decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE,
          tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
        ),
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )

      sampler = OpenTelemetry::Sampling::Hierarchical::Sampler.new first_sampler, second_sampler
      _(
        sampler.should_sample?(
          trace_id: trace_id,
          parent_context: nil,
          links: [],
          name: name,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal true

      first_sampler.verify
      second_sampler.verify
    end

    it 'returns DROP if both samplers return DROP' do
      trace_id = SecureRandom.uuid.to_s
      name = SecureRandom.uuid.to_s

      first_sampler = Minitest::Mock.new
      second_sampler = Minitest::Mock.new

      first_sampler.expect(
        :should_sample?,
        OpenTelemetry::SDK::Trace::Samplers::Result.new(
          decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
          tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
        ),
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )
      second_sampler.expect(
        :should_sample?,
        OpenTelemetry::SDK::Trace::Samplers::Result.new(
          decision: OpenTelemetry::SDK::Trace::Samplers::Decision::DROP,
          tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
        ),
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )

      sampler = OpenTelemetry::Sampling::Hierarchical::Sampler.new first_sampler, second_sampler
      _(
        sampler.should_sample?(
          trace_id: trace_id,
          parent_context: nil,
          links: [],
          name: name,
          kind: :internal,
          attributes: {}
        ).sampled?
      ).must_equal false

      first_sampler.verify
      second_sampler.verify
    end
  end
end
