# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'lib/opentelemetry/instrumentation/grpc/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-grpc'
  spec.version     = OpenTelemetry::Instrumentation::Grpc::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'gRPC instrumentation for the OpenTelemetry framework'
  spec.description = 'gRPC instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.required_ruby_version = '>= 3.3'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('example/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']

  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.25'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = "https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/#{spec.name}/v#{spec.version}/instrumentation/grpc"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
