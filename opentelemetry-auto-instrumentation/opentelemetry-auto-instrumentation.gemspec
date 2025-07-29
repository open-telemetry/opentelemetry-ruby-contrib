# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-auto-instrumentation'
  spec.version     = VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'auto-instrumentation for opentelemetry ruby'
  spec.description = 'auto-instrumentation for opentelemetry ruby'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE']

  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'opentelemetry-api', '~> 1.4.0'
  spec.add_dependency 'opentelemetry-exporter-otlp', '~> 0.29.1'
  spec.add_dependency 'opentelemetry-helpers-mysql', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-helpers-sql-obfuscation', '~> 0.3.0'
  spec.add_dependency 'opentelemetry-instrumentation-all', '~> 0.72.0'
  spec.add_dependency 'opentelemetry-resource-detector-aws', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-resource-detector-azure', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-resource-detector-container', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-resource-detector-google_cloud_platform', '~> 0.2.0'
  spec.add_dependency 'opentelemetry-sdk', '~> 1.6.0'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/opentelemetry-auto-instrumentation'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
