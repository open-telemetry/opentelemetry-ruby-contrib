# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/cache')

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
    it('should call the matching rule') do
      trace_id = SecureRandom.uuid.to_s
      name = SecureRandom.uuid.to_s
      fallback_sampler = Minitest::Mock.new
      result = OpenTelemetry::SDK::Trace::Samplers::Result.new(
        decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE,
        tracestate: OpenTelemetry::Trace::Tracestate.from_hash({})
      )
      fallback_sampler.expect(:nil?, false)

      cache = Minitest::Mock.new
      rule = Minitest::Mock.new
      resource = OpenTelemetry::SDK::Resources::Resource.create({})
      sampler = OpenTelemetry::Sampling::XRay::Cache.stub(:new, cache) do
        OpenTelemetry::Sampling::XRay::Sampler.new(
          resource: resource,
          fallback_sampler: fallback_sampler
        )
      end
      cache.expect(:get_first_matching_rule, rule, [], attributes: {}, resource: resource)
      rule.expect(:nil?, false)
      rule.expect(
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
      cache.verify
      rule.verify
    end

    it('should call the fallback sampler if there is no matching rule') do
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

      cache = Minitest::Mock.new
      resource = OpenTelemetry::SDK::Resources::Resource.create({})
      sampler = OpenTelemetry::Sampling::XRay::Cache.stub(:new, cache) do
        OpenTelemetry::Sampling::XRay::Sampler.new(
          resource: resource,
          fallback_sampler: fallback_sampler
        )
      end
      cache.expect(:get_first_matching_rule, nil, [], attributes: {}, resource: resource)

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
      cache.verify
    end
  end
end
