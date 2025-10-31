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
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'opentelemetry-instrumentation-action_mailer', '~> 0.6'
  spec.add_dependency 'opentelemetry-instrumentation-action_pack', '~> 0.15'
  spec.add_dependency 'opentelemetry-instrumentation-action_view', '~> 0.11'
  spec.add_dependency 'opentelemetry-instrumentation-active_job', '~> 0.10'
  spec.add_dependency 'opentelemetry-instrumentation-active_record', '~> 0.11'
  spec.add_dependency 'opentelemetry-instrumentation-active_storage', '~> 0.3'
  spec.add_dependency 'opentelemetry-instrumentation-active_support', '~> 0.10'
  spec.add_dependency 'opentelemetry-instrumentation-concurrent_ruby', '~> 0.23'

  spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/rails' if spec.respond_to?(:metadata)

  spec.post_install_message = File.read(File.expand_path('../../gemspecs/POST_INSTALL_MESSAGE', __dir__))
end
