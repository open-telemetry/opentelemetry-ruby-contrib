# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/gruf/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-gruf'
  spec.version     = OpenTelemetry::Instrumentation::Gruf::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Gruf instrumentation for the OpenTelemetry framework'
  spec.description = 'Gruf instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7.6'

  spec.add_dependency 'opentelemetry-api', '>=  1.0.0'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.22.1'

  spec.add_development_dependency 'appraisal', '~> 2.5'
  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'grpc_mock'
  spec.add_development_dependency 'gruf', '>= 2.15.1'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.0'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rubocop', '~> 1.56.1'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'webmock', '~> 3.19'
  spec.add_development_dependency 'yard', '~> 0.9'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby-contrib/opentelemetry-instrumentation-gruf/v#{OpenTelemetry::Instrumentation::Gruf::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/gruf'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby-contrib/opentelemetry-instrumentation-gruf/v#{OpenTelemetry::Instrumentation::Gruf::VERSION}"
  end
end
