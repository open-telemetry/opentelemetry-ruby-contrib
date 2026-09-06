# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'concurrent-ruby', '1.3.4'
  gem 'rails', '~> 7.0.4'
  gem 'puma'

  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rails'
  gem 'opentelemetry-sampler-xray', path: './../' # Use local version of the X-Ray Sampler
  # gem 'opentelemetry-sampler-xray' # Use RubyGems version of the X-Ray Sampler
end

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

class App < Rails::Application
  config.root = __dir__
  config.consider_all_requests_local = true

  routes.append do
    root to: 'welcome#index'
    get "/test" => 'welcome#test'
  end
end

class WelcomeController < ActionController::Base
  def index
    render inline: 'Successfully called "/" endpoint'
  end

  def test
    render inline: 'Successfully called "/test" endpoint'
  end
end

ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
ENV['OTEL_SERVICE_NAME'] ||= 'xray-sampler-on-rails-service'

OpenTelemetry::SDK.configure do |c|
  c.use_all
end

OpenTelemetry.tracer_provider.sampler = OpenTelemetry::Sampler::XRay::AWSXRayRemoteSampler.new(resource:OpenTelemetry::SDK::Resources::Resource.create({
  "service.name"=>"xray-sampler-on-rails-service"
}))

App.initialize!

run App

#### Running and using the Sample App
# To run this example run the `rackup` command with this file
# Example: rackup xray_sampling_on_rails_demonstration.ru
# Navigate to http://localhost:9292/
# Spans for any requests sampled by the X-Ray Sampler will appear in the console

#### Required configuration in the OpenTelemetry Collector
# In order for sampling rules to be obtained from AWS X-Ray, the awsproxy extension
# must be configured in the OpenTelemetry Collector, which will use your AWS credentials.
# - https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/awsproxy#aws-proxy
# Without the awsproxy extension, the X-Ray Sampler will use a fallback sampler
# with a sampling strategy of "1 request/second, plus 5% of any additional requests"

#### Testing out configurable X-Ray Sampling Rules against the "service.name" resource attribute.
# Create a new Sampling Rule with the following matching criteria in AWS CloudWatch Settings for X-Ray Traces.
# - https://console.aws.amazon.com/cloudwatch/home#xray:settings/sampling-rules
    # Matching Criteria
    # ServiceName = xray-sampler-on-rails-service
    # ServiceType = *
    # Host = *
    # ResourceARN = *
    # HTTPMethod = *
    # URLPath = *
# For the above matching criteria, try out the following settings to sample or not sample requests
# - Limit to 0r/sec then 0 fixed rate
# - Limit to 1r/sec then 0 fixed rate (May take 30 seconds for this setting to apply)
# - Limit to 0r/sec then 100% fixed rate

#### Testing out configurable X-Ray Sampling Rules against the "/test" endpoint in this sample app.
# Create a new Sampling Rule with the following matching criteria in AWS CloudWatch Settings for X-Ray Traces.
# - https://console.aws.amazon.com/cloudwatch/home#xray:settings/sampling-rules
    # Matching Criteria
    # ServiceName = *
    # ServiceType = *
    # Host = *
    # ResourceARN = *
    # HTTPMethod = *
    # URLPath = /test
# For the above matching criteria, try out the following settings to sample or not sample requests
# - Limit to 0r/sec then 0 fixed rate
# - Limit to 1r/sec then 0 fixed rate (May take 30 seconds for this setting to apply)
# - Limit to 0r/sec then 100% fixed rate