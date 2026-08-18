# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

namespace :each do
  task :appraisal, [:subtask] do |t, args|
    subtask = args[:subtask] || "version"
    if "#{subtask}" == "test"
      foreach_gem(['bundle exec appraisal rake test'])
    else
      foreach_gem("bundle exec appraisal #{subtask}")
    end
  end

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
    foreach_gem([
      "bundle config set path #{path}",
      "bundle config set clean false",
      "bundle install --jobs 4 --retry 3"
    ])
  end
end

task :appraisal, [:subtask] do |t, args|
  Rake::Task["each:appraisal"].invoke(args[:subtask])
end

task each: 'each:default'

task build: ['each:build']
task install: ['each:install']
task yard: ['each:yard']

task default: [:each]

EXCLUDED_DIRS = %w[vendor ruby_kafka que]

def foreach_gem(cmds)
  cmds = Array(cmds)  # string → ["string"], array stays array
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
    puts "::group:: ****#{dir}****"
    Dir.chdir(dir) do
      if defined?(Bundler)
        Bundler.with_unbundled_env do
          cmds.each { |cmd| sh(cmd) }
        end
      else
        cmds.each { |cmd| sh(cmd) }
      end
    end
    puts "::endgroup::"
  end
end
