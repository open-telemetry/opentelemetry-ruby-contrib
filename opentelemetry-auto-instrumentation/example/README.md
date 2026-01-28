# Example

## Installation

First, install the `opentelemetry-auto-instrumentation` gem using `gem install` (not through Bundler):

```bash
gem install opentelemetry-auto-instrumentation
```

This gem should be installed outside your Gemfile so that it can be loaded globally through the `RUBYOPT` environment variable.

## Simple Example (simple-example)

A basic Ruby application that demonstrates auto-instrumentation.

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=true OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" ruby app.rb
```

**What's happening:**

- `OTEL_RUBY_REQUIRE_BUNDLER=true` tells the gem to call `Bundler.require` during initialization
- `OTEL_TRACES_EXPORTER=console` outputs trace data to the console for visibility
- `RUBYOPT` ensures `opentelemetry-auto-instrumentation` is loaded before your application code

## Rails Example (rails-example)

A Rails application demonstrating auto-instrumentation integration.

### Without auto-instrumentation

```bash
bundle exec rackup config.ru
```

### With auto-instrumentation

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=false OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" bundle exec rackup config.ru
```

**What's happening:**

- `OTEL_RUBY_REQUIRE_BUNDLER=false` because Rails automatically calls `Bundler.require` during boot
- The OpenTelemetry gem is loaded first via `RUBYOPT`, then Rails initializes with instrumentation automatically applied

### Test the instrumentation

In another terminal, make a request to generate traces:

```bash
wget http://localhost:9292  # or use curl
```

You should see trace output in the console where the Rails server is running.

### Load sequence

The correct sequence is:

1. `opentelemetry-auto-instrumentation` is loaded (via `RUBYOPT`)
2. User libraries are required
3. `Bundler.require` is called (by Rails or manually)
4. OpenTelemetry SDK is initialized
5. Instrumentation is installed for loaded libraries

### Troubleshooting: Default Gem Version Conflicts

If you encounter an error like "You have already activated [gem] X.X.X, but your Gemfile requires [gem] Y.Y.Y", this indicates a version conflict with a default gem (such as `json` or `logger`). This occurs because your system's default Ruby gem versions are outdated compared to the fresh versions installed from the Gemfile in this folder.

#### Error example

```console
You have already activated json 2.6.3, but your Gemfile requires json 2.16.0.
Since json is a default gem, you can either remove your dependency on it or
try updating to a newer version of bundler that supports json as a default gem.
```

#### Solution

Install the specific gem version that your Gemfile requires:

```bash
gem install [gem-name] -v '[version]'
```

For example:

```bash
gem install json -v '2.16.0'
```

Then run your application again with auto-instrumentation.

#### Why this happens

The OpenTelemetry gem is loaded early in the Ruby startup process via `RUBYOPT`. If any of its dependencies activate a default gem version that differs from what your Gemfile specifies, Bundler will raise a conflict error. Installing the required version explicitly resolves this issue by replacing the system default with the specific version your project needs.
