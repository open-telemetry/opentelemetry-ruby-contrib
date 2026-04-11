# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

namespace :each do
  task :bundle_install do
    foreach_gem('bundle install')
  end

  task :bundle_update do
    foreach_gem('bundle update')
  end

  task :test do
    foreach_gem('bundle exec rake test')
  end

  task :yard do
    foreach_gem('bundle exec rake yard')
  end

  task :rubocop do
    foreach_gem('bundle exec rake rubocop')
  end

  task :default do
    foreach_gem('bundle exec rake')
  end

  task :build do
    foreach_gem('bundle exec rake build')
  end

  task :install do
    path = File.join(Dir.pwd, "vendor", "bundle")
    foreach_gem("bundle config set path #{path} && bundle config set clean false && bundle install --jobs 4 --retry 3")
  end
end

task each: 'each:default'

task build: ['each:build']
task install: ['each:install']
task yard: ['each:yard']

task default: [:each]

EXCLUDED_DIRS = %w[vendor]

def foreach_gem(cmd)
  gemspecs =
    Dir.glob("**/opentelemetry-*.gemspec")
       .reject do |path|
         EXCLUDED_DIRS.any? do |d|
           path.include?("/#{d}/") || path.start_with?("#{d}/")
         end
       end
       .sort

  gemspecs.each do |gemspec|
    name = File.basename(gemspec, ".gemspec")
    dir = File.dirname(gemspec)
    puts "**** Entering #{dir}"
    Dir.chdir(dir) do
      if defined?(Bundler)
        Bundler.with_unbundled_env do
          sh(cmd)
        end
      else
        sh(cmd)
      end
    end
  end
end
