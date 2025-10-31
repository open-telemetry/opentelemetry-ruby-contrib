# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'lib/opentelemetry/processor/baggage/version'

Gem::Specification.new do |spec|
  spec.name          = 'opentelemetry-processor-baggage'
  spec.version       = OpenTelemetry::Processor::Baggage::VERSION
  spec.authors       = ['OpenTelemetry Authors']
  spec.email         = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Baggage Span Processor for the OpenTelemetry framework'
  spec.description = 'Baggage Span Processor for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'opentelemetry-sdk', '~> 1.10'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/processor/baggage'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end

  spec.post_install_message = File.read(File.expand_path('../../gemspecs/POST_INSTALL_MESSAGE', __dir__))
end
