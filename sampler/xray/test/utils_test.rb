# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Sampler::XRay::Utils do
  POSITIVE_TESTS = [
    ['*', ''],
    ['foo', 'foo'],
    ['foo*bar*?', 'foodbaris'],
    ['?o?', 'foo'],
    ['*oo', 'foo'],
    ['foo*', 'foo'],
    ['*o?', 'foo'],
    ['*', 'boo'],
    ['', ''],
    ['a', 'a'],
    ['*a', 'a'],
    ['*a', 'ba'],
    ['a*', 'a'],
    ['a*', 'ab'],
    ['a*a', 'aa'],
    ['a*a', 'aba'],
    ['a*a*', 'aaaaaaaaaaaaaaaaaaaaaaa'],
    ['a*b*a*b*a*b*a*b*a*', 'akljd9gsdfbkjhaabajkhbbyiaahkjbjhbuykjakjhabkjhbabjhkaabbabbaaakljdfsjklababkjbsdabab'],
    ['a*na*ha', 'anananahahanahanaha'],
    ['***a', 'a'],
    ['**a**', 'a'],
    ['a**b', 'ab'],
    ['*?', 'a'],
    ['*??', 'aa'],
    ['*?', 'a'],
    ['*?*a*', 'ba'],
    ['?at', 'bat'],
    ['?at', 'cat'],
    ['?o?se', 'horse'],
    ['?o?se', 'mouse'],
    ['*s', 'horses'],
    ['J*', 'Jeep'],
    ['J*', 'jeep'],
    ['*/foo', '/bar/foo'],
    ['ja*script', 'javascript'],
    ['*', nil],
    ['*', ''],
    ['*', 'HelloWorld'],
    ['HelloWorld', 'HelloWorld'],
    ['Hello*', 'HelloWorld'],
    ['*World', 'HelloWorld'],
    ['?ello*', 'HelloWorld'],
    ['Hell?W*d', 'HelloWorld'],
    ['*.World', 'Hello.World'],
    ['*.World', 'Bye.World']
  ].freeze

  NEGATIVE_TESTS = [
    ['', 'whatever'],
    ['/', 'target'],
    ['/', '/target'],
    ['foo', 'bar'],
    ['f?o', 'boo'],
    ['f??', 'boo'],
    ['fo*', 'boo'],
    ['f?*', 'boo'],
    ['abcd', 'abc'],
    ['??', 'a'],
    ['??', 'a'],
    ['*?*a', 'a'],
    ['a*na*ha', 'anananahahanahana'],
    ['*s', 'horse']
  ].freeze

  it 'test_wildcard_match_with_only_wildcard' do
    assert OpenTelemetry::Sampler::XRay::Utils.wildcard_match('*', nil)
  end

  it 'test_wildcard_match_with_undefined_pattern' do
    refute OpenTelemetry::Sampler::XRay::Utils.wildcard_match(nil, '')
  end

  it 'test_wildcard_match_with_empty_pattern_and_text' do
    assert OpenTelemetry::Sampler::XRay::Utils.wildcard_match('', '')
  end

  it 'test_wildcard_match_with_regex_success' do
    POSITIVE_TESTS.each do |test|
      puts "#{test[0]} --- #{test[1]}" unless OpenTelemetry::Sampler::XRay::Utils.wildcard_match(test[0], test[1])
      assert OpenTelemetry::Sampler::XRay::Utils.wildcard_match(test[0], test[1])
    end
  end

  it 'test_wildcard_match_with_regex_failure' do
    NEGATIVE_TESTS.each do |test|
      refute OpenTelemetry::Sampler::XRay::Utils.wildcard_match(test[0], test[1])
    end
  end

  it 'test_attribute_match_with_undefined_attributes' do
    rule_attributes = { 'string' => 'string', 'string2' => 'string2' }
    refute OpenTelemetry::Sampler::XRay::Utils.attribute_match?(nil, rule_attributes)
    refute OpenTelemetry::Sampler::XRay::Utils.attribute_match?({}, rule_attributes)
    refute OpenTelemetry::Sampler::XRay::Utils.attribute_match?({ 'string' => 'string' }, rule_attributes)
  end

  it 'test_attribute_match_with_undefined_rule_attributes' do
    attr = {
      'number' => 1,
      'string' => 'string',
      'undefined' => nil,
      'boolean' => true
    }
    assert OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attr, nil)
  end

  it 'test_attribute_match_successful_match' do
    attr = { 'language' => 'english' }
    rule_attribute = { 'language' => 'en*sh' }
    assert OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attr, rule_attribute)
  end

  it 'test_attribute_match_failed_match' do
    attr = { 'language' => 'french' }
    rule_attribute = { 'language' => 'en*sh' }
    refute OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attr, rule_attribute)
  end

  it 'test_attribute_match_extra_attributes_success' do
    attr = {
      'number' => 1,
      'string' => 'string',
      'undefined' => nil,
      'boolean' => true
    }
    rule_attribute = { 'string' => 'string' }
    assert OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attr, rule_attribute)
  end

  it 'test_attribute_match_extra_attributes_failure' do
    attr = {
      'number' => 1,
      'string' => 'string',
      'undefined' => nil,
      'boolean' => true
    }
    rule_attribute = { 'string' => 'string', 'number' => '1' }
    refute OpenTelemetry::Sampler::XRay::Utils.attribute_match?(attr, rule_attribute)
  end
end
