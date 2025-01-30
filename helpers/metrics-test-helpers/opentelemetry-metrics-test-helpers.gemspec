# frozen_string_literal: true

require_relative 'lib/opentelemetry/metrics_test_helpers/version'

Gem::Specification.new do |spec|
  spec.name = 'opentelemetry-metrics-test-helpers'
  spec.version = OpenTelemetry::MetricsTestHelpers::VERSION
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary = 'Test helpers for adding metrics to instrumentation libraries'
  spec.homepage = 'https://github.com/open-telemetry/opentelemetry-ruby-contrib'
  spec.required_ruby_version = '>= 2.7.0'
  spec.license = 'Apache-2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'minitest'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
