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
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'opentelemetry-instrumentation-active_model_serializers', '~> 0.20.1'
  spec.add_dependency 'opentelemetry-instrumentation-aws_sdk', '~> 0.4.1'
  spec.add_dependency 'opentelemetry-instrumentation-bunny', '~> 0.20.1'
  spec.add_dependency 'opentelemetry-instrumentation-concurrent_ruby', '~> 0.21.1'
  spec.add_dependency 'opentelemetry-instrumentation-dalli', '~> 0.24.1'
  spec.add_dependency 'opentelemetry-instrumentation-delayed_job', '~> 0.20.1'
  spec.add_dependency 'opentelemetry-instrumentation-ethon', '~> 0.21.1'
  spec.add_dependency 'opentelemetry-instrumentation-excon', '~> 0.21.1'
  spec.add_dependency 'opentelemetry-instrumentation-faraday', '~> 0.23.1'
  spec.add_dependency 'opentelemetry-instrumentation-grape', '~> 0.1.3'
  spec.add_dependency 'opentelemetry-instrumentation-graphql', '~> 0.26.2'
  spec.add_dependency 'opentelemetry-instrumentation-gruf', '~> 0.1.0'
  spec.add_dependency 'opentelemetry-instrumentation-http', '~> 0.23.1'
  spec.add_dependency 'opentelemetry-instrumentation-http_client', '~> 0.22.1'
  spec.add_dependency 'opentelemetry-instrumentation-koala', '~> 0.20.1'
  spec.add_dependency 'opentelemetry-instrumentation-lmdb', '~> 0.22.1'
  spec.add_dependency 'opentelemetry-instrumentation-mongo', '~> 0.22.1'
  spec.add_dependency 'opentelemetry-instrumentation-mysql2', '~> 0.24.2'
  spec.add_dependency 'opentelemetry-instrumentation-net_http', '~> 0.22.1'
  spec.add_dependency 'opentelemetry-instrumentation-pg', '~> 0.25.2'
  spec.add_dependency 'opentelemetry-instrumentation-que', '~> 0.6.1'
  spec.add_dependency 'opentelemetry-instrumentation-racecar', '~> 0.2.1'
  spec.add_dependency 'opentelemetry-instrumentation-rack', '~> 0.23.1'
  spec.add_dependency 'opentelemetry-instrumentation-rails', '~> 0.27.1'
  spec.add_dependency 'opentelemetry-instrumentation-rake', '~> 0.2.1'
  spec.add_dependency 'opentelemetry-instrumentation-rdkafka', '~> 0.3.1'
  spec.add_dependency 'opentelemetry-instrumentation-redis', '~> 0.25.1'
  spec.add_dependency 'opentelemetry-instrumentation-resque', '~> 0.4.1'
  spec.add_dependency 'opentelemetry-instrumentation-restclient', '~> 0.22.1'
  spec.add_dependency 'opentelemetry-instrumentation-ruby_kafka', '~> 0.20.1'
  spec.add_dependency 'opentelemetry-instrumentation-sidekiq', '~> 0.24.1'
  spec.add_dependency 'opentelemetry-instrumentation-sinatra', '~> 0.23.1'
  spec.add_dependency 'opentelemetry-instrumentation-trilogy', '~> 0.56.1'

  spec.add_development_dependency 'active_model_serializers'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.55.1'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/all'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
