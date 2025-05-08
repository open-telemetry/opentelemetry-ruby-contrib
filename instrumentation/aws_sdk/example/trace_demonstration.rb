# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::AwsSdk'
end

# For more examples and options, see also https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/observability.html 
otel_provider = Aws::Telemetry::OTelProvider.new
sns = Aws::SNS::Client.new(telemetry_provider: otel_provider)
sns.publish message: 'ruby sending message to sns'
