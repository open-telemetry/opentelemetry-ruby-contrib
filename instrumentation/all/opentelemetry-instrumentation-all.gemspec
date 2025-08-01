# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'opentelemetry/instrumentation/all/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-all'
  spec.version     = OpenTelemetry::Instrumentation::All::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'All-in-one instrumentation bundle for the OpenTelemetry framework'
  spec.description = 'All-in-one instrumentation bundle for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = ">= #{File.read(File.expand_path('../../gemspecs/RUBY_REQUIREMENT', __dir__))}"

  spec.add_dependency 'opentelemetry-instrumentation-active_model_serializers', '~> 0.22.0'
  spec.add_dependency 'opentelemetry-instrumentation-aws_lambda', '~> 0.3.0'
  spec.add_dependency 'opentelemetry-instrumentation-aws_sdk', '~> 0.8.0'
  spec.add_dependency 'opentelemetry-instrumentation-bunny', '~> 0.22.0'
  spec.add_dependency 'opentelemetry-instrumentation-concurrent_ruby', '~> 0.22.0'
  spec.add_dependency 'opentelemetry-instrumentation-dalli', '~> 0.27.0'
  spec.add_dependency 'opentelemetry-instrumentation-delayed_job', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-ethon', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-excon', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-faraday', '~> 0.27.0'
  spec.add_dependency 'opentelemetry-instrumentation-grape', '~> 0.3.0'
  spec.add_dependency 'opentelemetry-instrumentation-graphql', '~> 0.29.0'
  spec.add_dependency 'opentelemetry-instrumentation-grpc', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-instrumentation-gruf', '~> 0.3.0'
  spec.add_dependency 'opentelemetry-instrumentation-http', '~> 0.25.0'
  spec.add_dependency 'opentelemetry-instrumentation-http_client', '~> 0.24.0'
  spec.add_dependency 'opentelemetry-instrumentation-koala', '~> 0.21.0'
  spec.add_dependency 'opentelemetry-instrumentation-lmdb', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-mongo', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-mysql2', '~> 0.29.0'
  spec.add_dependency 'opentelemetry-instrumentation-net_http', '~> 0.23.0'
  spec.add_dependency 'opentelemetry-instrumentation-pg', '~> 0.30.0'
  spec.add_dependency 'opentelemetry-instrumentation-que', '~> 0.9.0'
  spec.add_dependency 'opentelemetry-instrumentation-racecar', '~> 0.4.0'
  spec.add_dependency 'opentelemetry-instrumentation-rack', '~> 0.26.0'
  spec.add_dependency 'opentelemetry-instrumentation-rails', '~> 0.36.0'
  spec.add_dependency 'opentelemetry-instrumentation-rake', '~> 0.3.1'
  spec.add_dependency 'opentelemetry-instrumentation-rdkafka', '~> 0.7.0'
  spec.add_dependency 'opentelemetry-instrumentation-redis', '~> 0.26.1'
  spec.add_dependency 'opentelemetry-instrumentation-resque', '~> 0.6.0'
  spec.add_dependency 'opentelemetry-instrumentation-restclient', '~> 0.24.0'
  spec.add_dependency 'opentelemetry-instrumentation-ruby_kafka', '~> 0.22.0'
  spec.add_dependency 'opentelemetry-instrumentation-sidekiq', '~> 0.26.0'
  spec.add_dependency 'opentelemetry-instrumentation-sinatra', '~> 0.25.0'
  spec.add_dependency 'opentelemetry-instrumentation-trilogy', '~> 0.61.0'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/all'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end

  spec.post_install_message = File.read(File.expand_path('../../gemspecs/POST_INSTALL_MESSAGE', __dir__))
end
