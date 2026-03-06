# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/resource/detector/aws/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-resource-detector-aws'
  spec.version     = OpenTelemetry::Resource::Detector::AWS::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'AWS resource detector for OpenTelemetry'
  spec.description = 'AWS resource detector for OpenTelemetry'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.files = Dir.glob('lib/**/*.rb') +
               ['LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'opentelemetry-sdk', '~> 1.10'
end
