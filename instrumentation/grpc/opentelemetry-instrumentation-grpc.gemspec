# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'lib/opentelemetry/instrumentation/grpc/version'

Gem::Specification.new do |spec|
  spec.name = 'opentelemetry-instrumentation-grpc'
  spec.version = OpenTelemetry::Instrumentation::Grpc::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'gRPC instrumentation for the OpenTelemetry framework'
  spec.description = 'gRPC instrumentation for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.license     = 'Apache-2.0'

  spec.required_ruby_version = '>= 3.1'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'opentelemetry-api', '~> 1.2'
  spec.add_dependency 'opentelemetry-instrumentation-base', '~> 0.23.0'

  spec.add_development_dependency 'appraisal', '~> 2.5'

  spec.add_development_dependency 'google-protobuf', '~> 4.29'
  spec.add_development_dependency 'grpc-tools', '~> 1.64'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-sdk', '~> 1.1'
  spec.add_development_dependency 'opentelemetry-test-helpers', '~> 0.4'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rubocop', '~> 1.71.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.23.0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'yard', '~> 0.9'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby-contrib/opentelemetry-instrumentation-grpc/v#{OpenTelemetry::Instrumentation::Grpc::VERSION}/file.CHANGELOG.html"
    spec.metadata['source_code_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/grpc'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues'
    spec.metadata['documentation_uri'] = "https://open-telemetry.github.io/opentelemetry-ruby-contrib/opentelemetry-instrumentation-grpc/v#{OpenTelemetry::Instrumentation::Grpc::VERSION}"
  end
end
