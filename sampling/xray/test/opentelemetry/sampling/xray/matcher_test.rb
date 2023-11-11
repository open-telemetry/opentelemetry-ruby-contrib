# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('test_helper')
require('opentelemetry/sampling/xray/matcher')

describe(OpenTelemetry::Sampling::XRay::Matcher) do
  describe('to_matcher') do
    it('returns a TrueMatcher for *') do
      _(
        OpenTelemetry::Sampling::XRay::Matcher.to_matcher('*')
      ).must_be_instance_of(
        OpenTelemetry::Sampling::XRay::TrueMatcher
      )
    end

    it('returns a StringMatcher for a string') do
      _(
        OpenTelemetry::Sampling::XRay::Matcher.to_matcher(SecureRandom.uuid.to_s)
      ).must_be_instance_of(
        OpenTelemetry::Sampling::XRay::StringMatcher
      )
    end

    it('returns a PatternMatcher for a glob pattern') do
      _(
        OpenTelemetry::Sampling::XRay::Matcher.to_matcher('a*b?c')
      ).must_be_instance_of(
        OpenTelemetry::Sampling::XRay::PatternMatcher
      )
    end
  end
end

describe(OpenTelemetry::Sampling::XRay::TrueMatcher) do
  describe('match?') do
    it('returns true') do
      _(
        OpenTelemetry::Sampling::XRay::TrueMatcher.new.match?(SecureRandom.uuid.to_s)
      ).must_equal(true)
    end
  end
end

describe(OpenTelemetry::Sampling::XRay::StringMatcher) do
  describe('match?') do
    it('returns true for the same string') do
      string = SecureRandom.uuid.to_s
      _(
        OpenTelemetry::Sampling::XRay::StringMatcher.new(string).match?(string)
      ).must_equal(true)
    end

    it('returns false for a different string') do
      _(
        OpenTelemetry::Sampling::XRay::StringMatcher.new(SecureRandom.uuid.to_s).match?(SecureRandom.uuid.to_s)
      ).must_equal(false)
    end
  end
end

describe(OpenTelemetry::Sampling::XRay::PatternMatcher) do
  describe('match?') do
    it('returns true for a matching string') do
      _(
        OpenTelemetry::Sampling::XRay::PatternMatcher.new('a*b?c').match?('abzc')
      ).must_equal(true)
      _(
        OpenTelemetry::Sampling::XRay::PatternMatcher.new('a*b?c').match?('axybzc')
      ).must_equal(true)
    end

    it('returns false for a non-matching string') do
      _(
        OpenTelemetry::Sampling::XRay::PatternMatcher.new('z*b?c').match?(SecureRandom.uuid.to_s)
      ).must_equal(false)
    end

    it('returns false for nil') do
      _(
        OpenTelemetry::Sampling::XRay::PatternMatcher.new('a*b?c').match?(nil)
      ).must_equal(false)
    end
  end
end
