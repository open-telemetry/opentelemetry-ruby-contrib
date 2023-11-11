# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')

describe(OpenTelemetry::Sampling::XRay::Sampler) do
  describe('#initialize') do
    it('should initialize') do
      _(
        OpenTelemetry::Sampling::XRay::Sampler.new(
          resource: OpenTelemetry::SDK::Resources::Resource.create({}),
          fallback_sampler: OpenTelemetry::SDK::Trace::Samplers.trace_id_ratio_based(rand)
        )
      ).wont_be_nil
    end

    it('should raise ArgumentError when resource is nil') do
      _(
        lambda {
          OpenTelemetry::Sampling::XRay::Sampler.new(
            resource: nil,
            fallback_sampler: OpenTelemetry::SDK::Trace::Samplers.trace_id_ratio_based(rand)
          )
        }
      ).must_raise(ArgumentError)
    end

    it('should raise ArgumentError when fallback_sampler is nil') do
      _(
        lambda {
          OpenTelemetry::Sampling::XRay::Sampler.new(
            resource: OpenTelemetry::SDK::Resources::Resource.create({}),
            fallback_sampler: nil
          )
        }
      ).must_raise(ArgumentError)
    end
  end

  describe('#should_sample?') do
    it('should call the fallback sampler') do
      trace_id = SecureRandom.uuid.to_s
      name = SecureRandom.uuid.to_s
      fallback_sampler = Minitest::Mock.new
      result = OpenTelemetry::SDK::Trace::Samplers::Result.new(
        decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE,
        tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
      )
      fallback_sampler.expect(:nil?, false)
      fallback_sampler.expect(
        :should_sample?,
        result,
        [],
        trace_id: trace_id,
        parent_context: nil,
        links: [],
        name: name,
        kind: :internal,
        attributes: {}
      )

      sampler = OpenTelemetry::Sampling::XRay::Sampler.new(
        resource: OpenTelemetry::SDK::Resources::Resource.create({}),
        fallback_sampler: fallback_sampler
      )

      _(
        sampler.should_sample?(
          trace_id: trace_id,
          parent_context: nil,
          links: [],
          name: name,
          kind: :internal,
          attributes: {}
        )
      ).must_equal(result)

      fallback_sampler.verify
    end
  end
end