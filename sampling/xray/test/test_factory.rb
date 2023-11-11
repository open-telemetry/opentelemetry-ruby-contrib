# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require('opentelemetry/sampling/xray/sampling_rule')

# @param [Hash] attributes
# @param [Integer] fixed_rate
# @param [String] host
# @param [String] http_method
# @param [Integer] priority
# @param [Integer] reservoir_size
# @param [String] resource_arn
# @param [String] rule_arn
# @param [String] rule_name
# @param [String] service_name
# @param [String] service_type
# @param [String] url_path
# @param [Integer] version
# @return [OpenTelemetry::Sampling::XRay::SamplingRule]
def build_rule(
  attributes: {},
  fixed_rate: rand(0..100),
  host: '*',
  http_method: '*',
  priority: rand(0..100),
  reservoir_size: rand(0..100),
  resource_arn: '*',
  rule_arn: SecureRandom.uuid.to_s,
  rule_name: SecureRandom.uuid.to_s,
  service_name: '*',
  service_type: '*',
  url_path: '*',
  version: rand(0..100)
)
  OpenTelemetry::Sampling::XRay::SamplingRule.new(
    attributes: attributes,
    fixed_rate: fixed_rate,
    host: host,
    http_method: http_method,
    priority: priority,
    reservoir_size: reservoir_size,
    resource_arn: resource_arn,
    rule_arn: rule_arn,
    rule_name: rule_name,
    service_name: service_name,
    service_type: service_type,
    url_path: url_path,
    version: version
  )
end
