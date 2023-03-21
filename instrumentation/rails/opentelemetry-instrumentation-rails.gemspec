# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/instrumentation/rails/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-instrumentation-rails'
  spec.version     = OpenTelemetry::Instrumentation::Rails::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'Rails instrumentation for the OpenTelemetry framework'
  spec.description = 'Rails instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'opentelemetry-api', '~> 1.0'
  spec.add_dependency 'opentelemetry-instrumentation-action_pack', '~> 0.5.0'
  spec.add_dependency 'opentelemetry-instrumentation-action_view', '~> 0.4.0'
  spec.add_dependency 'opentelemetry-instrumentation-active_job', '~> 0.4.0'
  spec.add_dependency 'opentelemetry-instrumentation-active_record', '~> 0.5.0'
  spec.add_dependency 'opentelemetry-instrumentation-active_support', '~> 0.3.0'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.21.0'

  spec.add_development_dependency 'appraisal', '~> 2.4.1'
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.1'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'rack-test', '~> 2.1.0'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.48.0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'webmock', '~> 3.18.1'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/rails' if spec.respond_to?(:metadata)
end
