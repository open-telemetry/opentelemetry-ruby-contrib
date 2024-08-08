# test/instrumentation_generator_test.rb

require 'minitest/autorun'
require 'mocha/minitest'
require 'thor'
require_relative '../instrumentation_generator'

class InstrumentationGeneratorTest < Minitest::Test
  def setup
    @instrumentation_name = 'new_instrumentation'
    @generator = InstrumentationGenerator.new([@instrumentation_name])

    @generator.stubs(:template)
    @generator.stubs(:insert_into_file)
    @generator.stubs(:puts)
  end

  def test_root_files
    @generator.root_files

    assert @generator.template('templates/rubocop.yml.tt', 'instrumentation/new_instrumentation/.rubocop.yml')
    assert @generator.template('templates/yardopts.tt', 'instrumentation/new_instrumentation/.yardopts')
    assert @generator.template('templates/Appraisals', 'instrumentation/new_instrumentation/Appraisals')
    assert @generator.template('templates/CHANGELOG.md.tt', 'instrumentation/new_instrumentation/CHANGELOG.md')
    assert @generator.template('templates/Gemfile', 'instrumentation/new_instrumentation/Gemfile')
    assert @generator.template('templates/LICENSE', 'instrumentation/new_instrumentation/LICENSE')
    assert @generator.template('templates/gemspec.tt', 'instrumentation/new_instrumentation/opentelemetry-instrumentation-new_instrumentation.gemspec')
    assert @generator.template('templates/Rakefile', 'instrumentation/new_instrumentation/Rakefile')
    assert @generator.template('templates/Readme.md.tt', 'instrumentation/new_instrumentation/README.md')
  end

  def test_lib_files
    @generator.lib_files

    assert @generator.template('templates/lib/entrypoint.rb', 'instrumentation/new_instrumentation/lib/opentelemetry-instrumentation-new_instrumentation.rb')
    assert @generator.template('templates/lib/instrumentation.rb.tt', 'instrumentation/new_instrumentation/lib/opentelemetry/instrumentation.rb')
    assert @generator.template('templates/lib/instrumentation/instrumentation_name.rb.tt', 'instrumentation/new_instrumentation/lib/opentelemetry/instrumentation/new_instrumentation.rb')
    assert @generator.template('templates/lib/instrumentation/instrumentation_name/instrumentation.rb.tt', 'instrumentation/new_instrumentation/lib/opentelemetry/instrumentation/new_instrumentation/instrumentation.rb')
    assert @generator.template('templates/lib/instrumentation/instrumentation_name/version.rb.tt', 'instrumentation/new_instrumentation/lib/opentelemetry/instrumentation/new_instrumentation/version.rb')
  end

  def test_test_files
    @generator.test_files

    assert @generator.template('templates/test/test_helper.rb', 'instrumentation/new_instrumentation/test/test_helper.rb')
    assert @generator.template('templates/test/instrumentation.rb', 'instrumentation/new_instrumentation/test/opentelemetry/instrumentation/new_instrumentation/instrumentation_test.rb')
  end

  def test_add_to_releases
    @generator.add_to_releases

    expected_release_details = <<-HEREDOC
  - name: opentelemetry-instrumentation-new_instrumentation
    directory: instrumentation/new_instrumentation
    version_constant: [OpenTelemetry, Instrumentation, NewInstrumentation, VERSION]\n
    HEREDOC

    assert @generator.insert_into_file('.toys/.data/releases.yml', expected_release_details.strip, after: "gems:\n")
  end

  def test_add_to_instrumentation_all
    @generator.add_to_instrumentation_all

    gemfile_text = "\ngem 'opentelemetry-instrumentation-new_instrumentation', path: '../new_instrumentation'"
    gemspec_text = "\n  spec.add_dependency 'opentelemetry-instrumentation-new_instrumentation', '~> 0.0.0'"
    all_rb_text = "\nrequire 'opentelemetry-instrumentation-new_instrumentation'"

    assert @generator.insert_into_file('instrumentation/all/Gemfile', gemfile_text, after: "gemspec\n")
    assert @generator.insert_into_file('instrumentation/all/opentelemetry-instrumentation-all.gemspec', gemspec_text, after: "spec.required_ruby_version = '>= 3.0'\n")
    assert @generator.insert_into_file('instrumentation/all/lib/opentelemetry/instrumentation/all.rb', all_rb_text, after: "# SPDX-License-Identifier: Apache-2.0\n")
  end

  def test_update_ci_workflow
    @generator.update_ci_workflow

    ci_file_text = "          - new_instrumentation\n"
    dependabot_file_text = "  - package-ecosystem: 'bundler'\n    directory: '/instrumentation/new_instrumentation'\n"

    assert @generator.insert_into_file('.github/workflows/ci-instrumentation.yml', ci_file_text, after: "        gem:\n")
    assert @generator.insert_into_file('.github/dependabot.yml', dependabot_file_text, after: "updates:\n")

    assert @generator.puts('Updated .github/workflows/ci-instrumentation.yml and .github/dependabot.yml successfully.')
  end
end
