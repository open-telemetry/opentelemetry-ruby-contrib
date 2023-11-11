# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')

describe(OpenTelemetry::Sampling::XRay::SamplingRule) do
  describe('#match?') do
    it('returns true when all properties are wildcards') do
      rule = build_rule

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns true when all properties except the host are wildcards and it matches') do
      host = SecureRandom.uuid.to_s
      rule = build_rule(host: host)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::NET_HOST_NAME => host
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_HOST => host
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the host are wildcards and it does not match') do
      rule = build_rule(host: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::NET_HOST_NAME => SecureRandom.uuid.to_s
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_HOST => SecureRandom.uuid.to_s
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the http_method are wildcards and it matches') do
      http_method = SecureRandom.uuid.to_s
      rule = build_rule(http_method: http_method)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => http_method
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the http_method are wildcards and it does not match') do
      rule = build_rule(http_method: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => SecureRandom.uuid.to_s
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the resource_arn are wildcards and it matches') do
      resource_arn = SecureRandom.uuid.to_s
      rule = build_rule(resource_arn: resource_arn)

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::AWS_ECS_CONTAINER_ARN => resource_arn
          )
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the resource_arn are wildcards and it does not match') do
      rule = build_rule(resource_arn: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::AWS_ECS_CONTAINER_ARN => SecureRandom.uuid.to_s
          )
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the service_name are wildcards and it matches') do
      service_name = SecureRandom.uuid.to_s
      rule = build_rule(service_name: service_name)

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => service_name
          )
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the service_name are wildcards and it does not match') do
      rule = build_rule(service_name: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => SecureRandom.uuid.to_s
          )
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the service_type are wildcards and it matches') do
      rule = build_rule(service_type: 'AWS::EC2::Instance')

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'aws_ec2'
          )
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the service_type are wildcards and it does not match') do
      rule = build_rule(service_type: 'AWS::EC2::Instance')

      _(
        rule.match?(
          attributes: {},
          resource: OpenTelemetry::SDK::Resources::Resource.create(
            OpenTelemetry::SemanticConventions::Resource::CLOUD_PLATFORM => 'aws_ecs'
          )
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the url_path are wildcards and the http_target matches') do
      url_path = SecureRandom.uuid.to_s
      rule = build_rule(url_path: url_path)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => url_path
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the url_path are wildcards and the http_target does not match') do
      rule = build_rule(url_path: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => SecureRandom.uuid.to_s
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the url_path are wildcards and the http_url matches') do
      url_path = "/#{SecureRandom.uuid}"
      rule = build_rule(url_path: url_path)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_URL => "http://#{SecureRandom.uuid}#{url_path}"
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the url_path are wildcards and the http_url does not match') do
      rule = build_rule(url_path: SecureRandom.uuid.to_s)

      _(
        rule.match?(
          attributes: {
            OpenTelemetry::SemanticConventions::Trace::HTTP_URL => "http://#{SecureRandom.uuid}/#{SecureRandom.uuid}"
          },
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
    end

    it('returns true when all properties except the attributes are wildcards and all attributes match') do
      attributes = {
        SecureRandom.uuid.to_s => SecureRandom.uuid.to_s,
        SecureRandom.uuid.to_s => SecureRandom.uuid.to_s,
        SecureRandom.uuid.to_s => SecureRandom.uuid.to_s
      }
      rule = build_rule(attributes: attributes)

      _(
        rule.match?(
          attributes: attributes,
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(true)
    end

    it('returns false when all properties except the attributes are wildcards and one attribute does not match') do
      key = SecureRandom.uuid.to_s
      attributes = {
        SecureRandom.uuid.to_s => SecureRandom.uuid.to_s,
        SecureRandom.uuid.to_s => SecureRandom.uuid.to_s,
        key => SecureRandom.uuid.to_s
      }
      rule = build_rule(attributes: attributes)

      _(
        rule.match?(
          attributes: attributes.merge(key => SecureRandom.uuid.to_s),
          resource: OpenTelemetry::SDK::Resources::Resource.create
        )
      ).must_equal(false)
    end
  end

  describe('#can_sample?') do
    it('increments the request count and returns true if it can borrow from the reservoir') do
      reservoir = Minitest::Mock.new
      statistic = Minitest::Mock.new
      rule = OpenTelemetry::Sampling::XRay::Reservoir.stub(:new, reservoir) do
        OpenTelemetry::Sampling::XRay::Statistic.stub(:new, statistic) { build_rule }
      end

      reservoir.expect(:borrow_or_take?, OpenTelemetry::Sampling::XRay::Reservoir::BORROW)
      statistic.expect(:increment_borrow_count, nil)
      statistic.expect(:increment_request_count, nil)

      _(rule.can_sample?).must_equal(true)

      reservoir.verify
      statistic.verify
    end

    it('increments the request count and returns true if it can take from the reservoir') do
      reservoir = Minitest::Mock.new
      statistic = Minitest::Mock.new
      rule = OpenTelemetry::Sampling::XRay::Reservoir.stub(:new, reservoir) do
        OpenTelemetry::Sampling::XRay::Statistic.stub(:new, statistic) { build_rule }
      end

      reservoir.expect(:borrow_or_take?, OpenTelemetry::Sampling::XRay::Reservoir::TAKE)
      statistic.expect(:increment_request_count, nil)
      statistic.expect(:increment_sampled_count, nil)

      _(rule.can_sample?).must_equal(true)

      reservoir.verify
      statistic.verify
    end

    it('returns true according to fixed_rate') do
      reservoir = Minitest::Mock.new
      statistic = Minitest::Mock.new
      rule = OpenTelemetry::Sampling::XRay::Reservoir.stub(:new, reservoir) do
        OpenTelemetry::Sampling::XRay::Statistic.stub(:new, statistic) { build_rule(fixed_rate: 2) }
      end

      reservoir.expect(:borrow_or_take?, nil)
      statistic.expect(:increment_request_count, nil)
      statistic.expect(:increment_sampled_count, nil)

      _(rule.can_sample?).must_equal(true)

      reservoir.verify
      statistic.verify
    end

    it('returns false according to fixed_rate') do
      reservoir = Minitest::Mock.new
      statistic = Minitest::Mock.new
      rule = OpenTelemetry::Sampling::XRay::Reservoir.stub(:new, reservoir) do
        OpenTelemetry::Sampling::XRay::Statistic.stub(:new, statistic) { build_rule(fixed_rate: 0) }
      end

      reservoir.expect(:borrow_or_take?, nil)
      statistic.expect(:increment_request_count, nil)

      _(rule.can_sample?).must_equal(false)

      reservoir.verify
      statistic.verify
    end
  end
end
