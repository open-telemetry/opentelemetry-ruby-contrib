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
    installeach_gem()
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
    installeach_gem()
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

def discover_gems
  gemspecs =
    Dir.glob("**/opentelemetry-*.gemspec")
       .reject do |path|
         EXCLUDED_DIRS.any? do |d|
           path.include?("/#{d}/") || path.start_with?("#{d}/")
         end
       end
       .map { |gemspec| File.dirname(gemspec) }
       .sort
end

def foreach_gem(cmds)
  cmds = Array(cmds)  # string → ["string"], array stays array
  discover_gems.each do |dir|
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
        #cmds.each { |cmd|
        #  output = IO.popen(cmd, &:read)
        #  puts "#{output}"
        #}
      else
        cmds.each { |cmd| sh(cmd) }
      end
    end
    puts "::endgroup::"
  end
end

def testeach_gem(max_procs: 4)
  discover_gems.each do |dir|
    puts "::group:: ****#{dir}****"

    gemfiles = Dir.glob(File.join(dir, "gemfiles", "*.gemfile")).sort
    running = []

    # Force Bundler to use root-level vendor path
    system("bundle config set --local path ../../vendor/bundle", chdir: dir)

    gemfiles.each do |gemfile|
      name = File.basename(gemfile, ".gemfile")
      rel_gemfile = File.join("gemfiles", "#{name}.gemfile")
      puts "Running tests for appraisal: #{name}"

      # Spawn a process for this appraisal
      cmd = "BUNDLE_GEMFILE=#{rel_gemfile} bundle exec rake test"

      pid = Process.spawn("/bin/bash", "-c", cmd, chdir: dir)
      running << pid

      # If pool is full, wait for one to finish
      if running.size >= max_procs
        finished = Process.wait
        running.delete(finished)
        raise "Tests failed for #{dir} (#{name})" unless $?.exitstatus == 0
      end
    end

    # Wait for remaining processes
    running.each do |pid|
      Process.wait(pid)
      raise "Tests failed for #{dir}" unless $?.exitstatus == 0
    end
    puts "::endgroup::"
  end
end

def installeach_gem()
  sh("echo $GEM_HOME")
  sh("cp -r vendor $GEM_HOME  || true")
  discover_gems.each do |dir|
    puts "::group:: ****#{dir}****"
    Bundler.with_unbundled_env do
      env = {
        "BUNDLE_GEMFILE" => File.join("Gemfile"),
      }
      Dir.chdir(dir) do
        sh(env, "bundle install")
      end
    end
    puts "::endgroup::"
  end
  sh("cp -r $GEM_HOME vendor || true")
end

def run_appraisalCmd(*args)
#  Bundler.with_unbundled_env do
    stdout, stderr, status = Open3.capture3("bundle", "exec", "appraisal", *args)
    raise "appraisal #{args.join(' ')} failed:\n#{stderr}" unless status.success?
    puts "appraisal #{args.join(' ')} output:\n#{stdout}"
    stdout
#  end
end
