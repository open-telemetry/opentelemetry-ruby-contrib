# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require('opentelemetry/sampling/xray/version')

Gem::Specification.new do |spec|
  spec.name = 'opentelemetry-sampling-xray'
  spec.version = OpenTelemetry::Sampling::XRay::VERSION
  spec.authors = ['OpenTelemetry Authors']
  spec.email = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary = 'XRay Remote Sampling Extension for the OpenTelemetry framework'
  spec.description = 'XRay Remote Sampling Extension for the OpenTelemetry framework'
  spec.homepage = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') + Dir.glob('*.md') + %w[LICENSE .yardopts]
  spec.require_paths = %w[lib]
  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency('opentelemetry-api', '~> 1.0')

  spec.add_development_dependency('bundler', '~> 2.4')
  spec.add_development_dependency('minitest', '~> 5.0')
  spec.add_development_dependency('opentelemetry-sdk', '~> 1.1')
  spec.add_development_dependency('rake', '~> 13.0')
  spec.add_development_dependency('rubocop', '~> 1.57.1')
  spec.add_development_dependency('yard', '~> 0.9')

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/sampling/xray'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
