# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/resource/detector/google_cloud_platform/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-resource-detector-google_cloud_platform'
  spec.version     = OpenTelemetry::Resource::Detector::GoogleCloudPlatform::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Google Cloud Platform resource detection helpers for OpenTelemetry'
  spec.description = 'Google Cloud Platform resource detection helpers for OpenTelemetry'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'google-cloud-env'
  spec.add_dependency 'opentelemetry-sdk', '~> 1.10'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/resources/container'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end

  spec.post_install_message = File.read(File.expand_path('../../gemspecs/POST_INSTALL_MESSAGE', __dir__))
end
