# frozen_string_literal: true

require "base64"
require "fileutils"
require "tmpdir"
require "release_utils"

class ReleasePerformer
  class Instance
    def initialize(parent, gem_name, gem_version, step)
      @parent = parent
      @gem_name = gem_name
      @gem_version = gem_version
      @utils = parent.utils
      @include_gem = ["all", "gem"].include?(step)
      @include_github_release = ["all", "github-release"].include?(step)
      @result = nil
    end

    attr_reader :gem_name
    attr_reader :gem_version

    def success?
      @result == true
    end

    def error?
      @result.is_a?(ReleaseUtils::ReleaseError)
    end

    def pending?
      @result.nil?
    end

    def error_messages
      error? ? @result.all_messages : nil
    end

    def perform
      raise "Already performed" unless @result.nil?
      raise "Already reported results" unless @parent.result.nil?
      @utils.raise_on_error = true
      perform_steps
      @result = true
    rescue ReleaseUtils::ReleaseError => e
      @result = e
      false
    ensure
      @utils.raise_on_error = false
    end

    private

    def perform_steps
      @parent.initial_setup
      verify unless @parent.skip_checks?

      check_release_exists
      check_gem_exists

      build_gem if @include_gem

      create_github_release(@changelog_content) if @include_github_release
      push_gem if @include_gem
    end

    def check_gem_exists
      return if !@parent.check_exists? || !@include_gem
      result = @utils.capture(["gem", "info", "-r", "-a", @gem_name])
      if result =~ /#{@gem_name} \(([\w\., ]+)\)/
        if Regexp.last_match[1].split(/,\s+/).include?(@gem_version)
          @utils.logger.warn("Gem already pushed for #{@gem_name} #{@gem_version}. Skipping.")
          @include_gem = false
        end
      end
    end

    def check_release_exists
      return if !@parent.check_exists? || !@include_github_release
      result = @utils.exec(["gh", "api",
                            "repos/#{@utils.repo_path}/releases/tags/#{@gem_name}/v#{@gem_version}",
                            "-H", "Accept: application/vnd.github.v3+json"],
                           out: :null, e: false)
      if result.success?
        @utils.logger.warn(
          "GitHub release already exists for #{@gem_name} #{@gem_version}. Skipping."
        )
        @include_github_release = false
      end
    end

    def verify
      @utils.error("Gem #{@gem_name} not known.") unless @utils.gem_info(@gem_name)
      @utils.verify_library_version(@gem_name, @gem_version)
      @changelog_content = @utils.verify_changelog_content(@gem_name, @gem_version)
      self
    end

    def create_github_release(content = nil)
      @utils.log("Creating github release of #{@gem_name} #{@gem_version} ...")
      body = ::JSON.dump(tag_name: "#{@gem_name}/v#{@gem_version}",
                         target_commitish: @parent.release_sha,
                         name: "#{@gem_name} #{@gem_version}",
                         body: content.to_s.strip)
      @utils.exec(["gh", "api", "repos/#{@utils.repo_path}/releases", "--input", "-",
                   "-H", "Accept: application/vnd.github.v3+json"],
                  in: [:string, body], out: :null)
      @utils.log("Release created.")
      self
    end

    def build_gem
      @utils.log("Building #{@gem_name} #{@gem_version} gem ...")
      @utils.gem_cd(@gem_name) do
        ::FileUtils.mkdir_p("pkg")
        @utils.exec(["gem", "build", "#{@gem_name}.gemspec",
                     "-o", "pkg/#{@gem_name}-#{@gem_version}.gem"])
      end
      @utils.log("Gem built")
      self
    end

    def push_gem
      @utils.log("Pushing #{@gem_name} #{@gem_version} to Rubygems ...")
      @utils.gem_cd(@gem_name) do
        built_file = "pkg/#{@gem_name}-#{@gem_version}.gem"
        @utils.error("#{built_file} didn't get built.") unless ::File.file? built_file
        if @parent.dry_run?
          @utils.log("DRY RUN: Gem pushed to Rubygems")
        else
          @utils.exec(["gem", "push", built_file])
          @utils.log("Gem pushed to Rubygems")
        end
      end
      self
    end
  end

  def initialize(utils,
                 release_sha: nil,
                 skip_checks: false,
                 rubygems_api_key: nil,
                 git_remote: nil,
                 gh_token: nil,
                 pr_info: nil,
                 check_exists: false,
                 dry_run: false)
    @utils = utils
    @release_sha = @utils.current_sha release_sha
    @skip_checks = skip_checks
    @rubygems_api_key = rubygems_api_key
    @git_remote = git_remote || "origin"
    @dry_run = dry_run
    @check_exists = check_exists
    @gh_token = gh_token
    @pr_info = pr_info
    @instances = []
    @extra_errors = []
    @result = nil
    @initial_setup_result = nil
  end

  attr_reader :utils
  attr_reader :release_sha
  attr_reader :rubygems_api_key
  attr_reader :git_remote
  attr_reader :result

  def dry_run?
    @dry_run
  end

  def skip_checks?
    @skip_checks
  end

  def check_exists?
    @check_exists
  end

  def add_extra_errors(*messages)
    @extra_errors.concat(messages)
  end

  def instance(gem_name, gem_version, only: nil)
    inst = Instance.new(self, gem_name, gem_version, only || "all")
    @instances << inst
    inst
  end

  def report_results
    raise "Already reported results" unless @result.nil?
    @extra_errors << "No releases were performed." if @instances.all?(&:pending?)
    @result = @extra_errors.empty? && @instances.all? { |inst| !inst.error? }
    if @pr_info
      report_text = build_report_text
      update_release_pr(report_text)
      open_release_failed_issue(report_text) unless @result
    else
      @utils.log("No PR to report results to.")
    end
    @result
  end

  def initial_setup
    if @initial_setup_result == true
      @utils.log("Skipping initial setup because it was done earlier.")
      return
    elsif @initial_setup_result == false
      @utils.error("Aborting because initial setup previously failed.")
    end
    @utils.log("Performing initial setup ...")
    @initial_setup_result = false
    unless @skip_checks
      @utils.verify_git_clean
      @utils.verify_repo_identity(git_remote: @git_remote)
      @utils.verify_github_checks(ref: @release_sha)
    end
    setup_rubygems_api_key
    @initial_setup_result = true
    @utils.log("Initial setup succeeded.")
  end

  private

  def setup_rubygems_api_key
    home_dir = ::ENV["HOME"]
    creds_path = "#{home_dir}/.gem/credentials"
    creds_exist = ::File.exist?(creds_path)
    if creds_exist && @rubygems_api_key
      @utils.error("Cannot set Rubygems credentials because #{creds_path} already exists")
    end
    if !creds_exist && !@rubygems_api_key
      @utils.error("Rubygems credentials needed but not provided")
    end
    if creds_exist && !@rubygems_api_key
      @utils.log("Using existing Rubygems credentials")
      return
    end
    ::FileUtils.mkdir_p("#{home_dir}/.gem")
    ::File.open(creds_path, "w", 0o600) do |file|
      file.puts("---\n:rubygems_api_key: #{@rubygems_api_key}")
    end
    utils = @utils
    at_exit { utils.exec(["shred", "-u", creds_path]) }
    @utils.log("Using provided Rubygems credentials")
  end

  def build_report_text
    lines =
      if @result
        ["All releases completed successfully."]
      else
        ["Release job completed with errors."]
      end
    unless @extra_errors.empty?
      lines << ""
      lines.concat(@extra_errors)
    end
    @instances.each do |inst|
      next if inst.pending?
      if inst.success?
        lines << "" << "Successfully released #{inst.gem_name} #{inst.gem_version}"
      else
        lines << "" << "Failed to release #{inst.gem_name} #{inst.gem_version}:"
        lines.concat(inst.error_messages)
      end
    end
    lines.join("\n")
  end

  def update_release_pr(report_text)
    pr_number = @pr_info["number"]
    @utils.log("Updating the release PR ##{pr_number} to report results ...")
    label = @result ? @utils.release_complete_label : @utils.release_error_label
    @utils.update_release_pr(pr_number, label: label, message: report_text, cur_pr: @pr_info)
    @utils.log("Updated release PR.")
    self
  end

  def open_release_failed_issue(report_text)
    @utils.log("Opening a new issue to report the failure ...")
    pr_number = @pr_info["number"]
    body = <<~STR
      A release job failed.

      Release PR: ##{pr_number}
      Commit: https://github.com/#{@utils.repo_path}/commit/#{@release_sha}

      ----

      #{report_text}
    STR
    title = "Release PR ##{pr_number} failed with errors"
    input = ::JSON.dump(title: title, body: body)
    response = @utils.capture(["gh", "api", "repos/#{@utils.repo_path}/issues", "--input", "-",
                               "-H", "Accept: application/vnd.github.v3+json"],
                              in: [:string, input])
    issue_number = ::JSON.parse(response)["number"]
    @utils.log("Issue #{issue_number} opened.")
    self
  end
end
