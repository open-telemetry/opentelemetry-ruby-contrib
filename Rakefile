# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require "open3"

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
    foreach_gem('bundle install')
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
NON_PARRALLEL_INSTALL = %w[instrumentation/http instrumentation/trilogy]

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
      if NON_PARRALLEL_INSTALL.include?(dir) && cmds.include?('bundle exec appraisal generate-install')
        puts "bundle install"
        result = IO.popen(["bundle", "install"], &:read)
        result = run_appraisalCmd("generate")
        appraisals_output = run_appraisalCmd("list")
        appraisals = appraisals_output.split("\n").map(&:strip).reject(&:empty?)

        appraisals.each do |app|
          out = run_appraisalCmd(app, "install")
        end
        puts "appraisal pre-install complete"
      end

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

def run_appraisalCmd(*args)
  Bundler.with_unbundled_env do
    stdout, stderr, status = Open3.capture3("bundle", "exec", "appraisal", *args)
    raise "appraisal #{args.join(' ')} failed:\n#{stderr}" unless status.success?
    puts "appraisal #{args.join(' ')} output:\n#{stdout}"
    stdout
  end
end
