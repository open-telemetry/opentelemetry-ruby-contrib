# Example

## Installation

First, install the `opentelemetry-auto-instrumentation` gem using `gem install` (not through Bundler):

```bash
gem install opentelemetry-auto-instrumentation
```

This gem should be installed outside your Gemfile so that it can be loaded globally through the `RUBYOPT` environment variable.

## Simple Example (simple-example)

A basic Ruby application that demonstrates opentelemetry-auto-instrumentation.

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=true OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" ruby app.rb
```

To also export metrics and logs to the console:

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=true \
  OTEL_TRACES_EXPORTER=console \
  OTEL_METRICS_EXPORTER=console \
  OTEL_LOGS_EXPORTER=console \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby app.rb
```

**What's happening:**

- `OTEL_RUBY_REQUIRE_BUNDLER=true` tells the gem to call `Bundler.require` during initialization
- `OTEL_TRACES_EXPORTER=console` outputs trace data to the console for visibility
- `OTEL_METRICS_EXPORTER=console` outputs metrics data to the console
- `OTEL_LOGS_EXPORTER=console` outputs log records to the console
- `RUBYOPT` ensures `opentelemetry-auto-instrumentation` is loaded before your application code

## Rails Example (rails-example)

A Rails application demonstrating opentelemetry-auto-instrumentation integration.

### Without opentelemetry-auto-instrumentation

```bash
bundle exec rackup config.ru
```

### With opentelemetry-auto-instrumentation

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=false OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" bundle exec rackup config.ru
```

To also export metrics and logs:

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=false \
  OTEL_TRACES_EXPORTER=console \
  OTEL_METRICS_EXPORTER=console \
  OTEL_LOGS_EXPORTER=console \
  RUBYOPT="-r opentelemetry-auto-instrumentation" bundle exec rackup config.ru
```

To send all signals to an OTLP collector:

```bash
bundle install
OTEL_RUBY_REQUIRE_BUNDLER=false \
  OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318" \
  OTEL_SERVICE_NAME="my-rails-app" \
  RUBYOPT="-r opentelemetry-auto-instrumentation" bundle exec rackup config.ru
```

**What's happening:**

- `OTEL_RUBY_REQUIRE_BUNDLER=false` because Rails automatically calls `Bundler.require` during boot
- The OpenTelemetry gem is loaded first via `RUBYOPT`, then Rails initializes with instrumentation automatically applied
- When no exporter env vars are set, traces, metrics, and logs default to the OTLP exporter sending to `http://localhost:4318`

### Test the instrumentation

In another terminal, make a request to generate traces:

```bash
curl http://localhost:9292
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

If you encounter an error like "You have already activated [gem] X.X.X, but your Gemfile requires [gem] Y.Y.Y", install the required version explicitly:

```bash
gem install [gem-name] -v '[version]'
```

This occurs because OpenTelemetry is loaded early via `RUBYOPT`, and if any of its dependencies activate a default gem version that differs from your Gemfile, Bundler raises a conflict error.

This won't cause issues in the operator because only OpenTelemetry-related gems will be included in your Ruby environment.
