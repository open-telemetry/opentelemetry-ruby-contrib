# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'lib/opentelemetry/propagator/google_cloud_platform/version'

Gem::Specification.new do |spec|
  spec.name          = 'opentelemetry-propagator-google_cloud_platform'
  spec.version       = OpenTelemetry::Propagator::GoogleCloudPlatform::VERSION
  spec.authors       = ['OpenTelemetry Authors']
  spec.email         = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'GoogleCloudPlatform Context Propagation Extension for the OpenTelemetry framework'
  spec.description = 'GoogleCloudPlatform Context Propagation Extension for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.71.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.23.0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'yard', '~> 0.9'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/propagator/google_cloud_platform'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end

  spec.post_install_message = File.read(File.expand_path('../../POST_INSTALL_MESSAGE', __dir__))
end
