# Local Development Setup

This guide explains how to set up your local environment for development with OpenTelemetry Ruby Contrib.

## Using Local Git Repositories

The Gemfiles in this repository use Git sources for internal dependencies. This allows renovatebot and released code to always fetch from the canonical repository. However, when developing locally or running tests in CI, you often want to test changes across multiple gems without pushing to GitHub.

Bundler supports **local Git repository overrides**[bundler-local-git-repos] which allow you to point to your local checkout instead of fetching from GitHub.

[bundler-local-git-repos]: https://bundler.io/guides/git.html#local-git-repos

### Setup

#### Quick Setup (Recommended)

Run the setup script from the repository root:

```bash
./bin/setup-local-dev
```

This will automatically configure Bundler to use your local repository.

#### Manual Setup

1. **Clone the repository** (if you haven't already):

   ```bash
   git clone https://github.com/open-telemetry/opentelemetry-ruby-contrib.git
   cd opentelemetry-ruby-contrib
   ```

2. **Configure Bundler to use your local checkout**:

   ```bash
   bundle config local.opentelemetry-ruby-contrib /Users/arielvalentin/github/opentelemetry-ruby-contrib
   ```

   Replace the path with the actual path to your local clone.

3. **Install dependencies**:

   ```bash
   bundle install
   ```

### How It Works

When you configure a local override, Bundler will:

- Use your local repository instead of cloning from GitHub
- Check that your local repository is on a branch that contains the commit specified in the Gemfile.lock
- Allow you to make changes locally and have them immediately reflected in dependent gems

### Verification

To verify your local override is active:

```bash
bundle config local.opentelemetry-ruby-contrib
```

You should see the path to your local repository.

### Removing Local Override

To stop using the local override and revert to GitHub sources:

```bash
bundle config --delete local.opentelemetry-ruby-contrib
```

### Example Workflow

1. Make changes to `instrumentation/base/lib/opentelemetry/instrumentation/base.rb`
2. Switch to another gem that depends on it, e.g., `instrumentation/rails/`
3. Run tests: `cd instrumentation/rails && bundle exec rake test`
4. Your changes from `instrumentation/base` are automatically used!

No need to publish gems or update version numbers during development.

### Troubleshooting

**Issue**: Bundler says "The branch X in your local repository does not contain the commit Y"

**Solution**: This happens when your Gemfile.lock references a specific commit that doesn't exist in your local branch. To fix:

```bash
bundle update <gem-name>
```

This will update the lockfile to use the current state of your local repository.

**Issue**: Changes aren't being picked up

**Solution**: Make sure you've configured the local override and that you're in the correct branch:

```bash
bundle config local.opentelemetry-instrumentation-base
git branch --show-current
```

## Running Tests

Each gem has its own test suite. To run all tests for a specific gem:

```bash
cd instrumentation/rails
bundle appraisal generate
bundle appraisal install
bundle exec appraisal rake test
```

## Additional Resources

- [Bundler Git Sources Documentation](https://bundler.io/guides/git.html)
