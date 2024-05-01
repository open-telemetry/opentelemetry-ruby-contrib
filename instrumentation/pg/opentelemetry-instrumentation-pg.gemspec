# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/pg/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-pg'
  spec.version     = OpenTelemetry::Instrumentation::PG::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'PG (PostgreSQL) instrumentation for the OpenTelemetry framework'
  spec.description = 'PG (PostgreSQL) instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'
  spec.add_dependency 'opentelemetry-helpers-sql-obfuscation'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.22.1'

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'appraisal', '~> 2.5'
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.1'
  spec.add_development_dependency 'opentelemetry-test-helpers', '~> 0.3'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'
  spec.add_development_dependency 'rubocop', '~> 1.62'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'yard', '~> 0.9'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/pg'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
