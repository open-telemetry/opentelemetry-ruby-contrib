# Example

## Installation

Install opentelemetry-auto-instrumentation through `gem install`
Then `bundle install`

## Simple Example (simple-example)

```bash
OTEL_RUBY_REQUIRE_BUNDLER=true  OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" OTEL_RUBY_OPERATOR=false ruby app.rb
```

## Rails Example (rails-example)

Without auto-instrumentation

```bash
bundle exec rackup config.ru
```

In other terminal make the request call

```bash
wget http://localhost:9292
# or curl http://localhost:9292 if you have curl on system
```

With auto-instrumentation

```bash
OTEL_RUBY_REQUIRE_BUNDLER=false  OTEL_TRACES_EXPORTER=console RUBYOPT="-r opentelemetry-auto-instrumentation" OTEL_RUBY_OPERATOR=false bundle exec rackup config.ru
```

The load sequence must be opentelemetry-auto-instrumentation -> user library -> bundler.require (initialize otel sdk and instrumentation installation)

In other terminal make the request call

```bash
wget http://localhost:9292
# or curl http://localhost:9292 if you have curl on system
```

### Troubleshooting: Default Gem Version Conflicts

If you encounter an error like "You have already activated [gem] X.X.X, but your Gemfile requires [gem] Y.Y.Y", this indicates a version conflict with a default gem (such as `json`, `bigdecimal`, or `logger`).

**Error example:**
```
You have already activated json 2.6.3, but your Gemfile requires json 2.16.0.
Since json is a default gem, you can either remove your dependency on it or
try updating to a newer version of bundler that supports json as a default gem.
```

**Solution:**

Install the specific gem version that your Gemfile requires:

```bash
gem install [gem-name] -v '[version]'
```

For example:
```bash
gem install json -v '2.16.0'
```

Then run your application again with auto-instrumentation.

**Why this happens:**

When using `RUBYOPT="-r opentelemetry-auto-instrumentation"` with `bundle exec`, the OpenTelemetry gem is loaded before `bundle exec` runs. If the OpenTelemetry dependencies activate a default gem version that differs from what your Gemfile specifies, Bundler will raise an error. Installing the required version explicitly resolves this conflict.
