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
