# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/trilogy/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-trilogy'
  spec.version     = OpenTelemetry::Instrumentation::Trilogy::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Trilogy instrumentation for the OpenTelemetry framework'
  spec.description = 'Adds auto instrumentation that includes SQL metadata'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'opentelemetry-helpers-mysql'
  spec.add_dependency 'opentelemetry-helpers-sql'
  spec.add_dependency 'opentelemetry-helpers-sql-obfuscation'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.25'
  spec.add_dependency 'opentelemetry-semantic_conventions', '>= 1.8.0'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/trilogy'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
