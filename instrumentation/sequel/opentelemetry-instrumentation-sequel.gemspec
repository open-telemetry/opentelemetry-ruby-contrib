# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/sequel/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-sequel'
  spec.version     = OpenTelemetry::Instrumentation::Sequel::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Sequel instrumentation for the OpenTelemetry framework'
  spec.description = 'Sequel instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'
  spec.add_dependency 'opentelemetry-common', '~> 0.20.0'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.22.1'
end
