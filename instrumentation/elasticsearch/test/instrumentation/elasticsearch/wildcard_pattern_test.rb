# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/elasticsearch'

describe OpenTelemetry::Instrumentation::Elasticsearch::WildcardPattern do
  let(:wildcard_obj) { OpenTelemetry::Instrumentation::Elasticsearch::WildcardPattern.new(pattern) }
  JSON.parse(
    File.read('test/fixtures/wildcard_matcher_tests.json', encoding: 'utf-8')
  ).each do |category, group|
    describe(category) do
      group.each do |pattern_from_json, examples|
        let(:pattern) { pattern_from_json }

        examples.each do |string, expectation|
          it("#{pattern_from_json} #{expectation ? '=~' : '!~'} #{string}") do
            _(wildcard_obj.match?(string)).must_equal(expectation)
          end
        end
      end
    end
  end
end
