# OpenTelemetry Auto Instrumentation

The `opentelemetry-auto-instrumentation` gem provides automatic loading and initialization of OpenTelemetry Ruby SDK for zero-code instrumentation of your applications.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework that provides a unified API, SDK, and tooling for instrumenting cloud-native applications. It captures distributed traces and metrics from your application, which can be analyzed using observability backends like Prometheus, Jaeger, and others.

## How does this gem fit in?

This gem enables OpenTelemetry instrumentation without modifying your application code. It automatically:

- Loads the OpenTelemetry SDK
- Initializes instrumentations for detected libraries
- Configures exporters and resource detectors

This gem is particularly useful with the [OpenTelemetry Operator][opentelemetry-operator] for Kubernetes environments.

## How do I get started?

Install the gem:

```console
gem install opentelemetry-auto-instrumentation
```

**Note:** Install via `gem install` rather than adding to your Gemfile, as this gem needs to load before your application starts.

### What gets installed?

Installing `opentelemetry-auto-instrumentation` automatically includes:

```console
opentelemetry-sdk
opentelemetry-api
opentelemetry-instrumentation-all
opentelemetry-exporter-otlp
opentelemetry-helpers-mysql
opentelemetry-helpers-sql-obfuscation
opentelemetry-resource-detector-azure
opentelemetry-resource-detector-container
opentelemetry-resource-detector-aws
```

## Usage Examples

### Basic Usage

Instrument any Ruby application:

```console
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### With Configuration

Set environment variables to configure exporters, resource detectors, and service name:

```console
export OTEL_TRACES_EXPORTER="otlp"
export OTEL_EXPORTER_OTLP_ENDPOINT="your-endpoint"
export OTEL_RUBY_RESOURCE_DETECTORS="container,azure"
export OTEL_SERVICE_NAME="your-service-name"

RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### Rails Applications

Rails automatically calls `Bundler.require`, so instrumentation works out of the box:

```console
RUBYOPT="-r opentelemetry-auto-instrumentation" rails server
```

### Selective Instrumentation

**Enable only specific instrumentations:**

```console
export OTEL_RUBY_ENABLED_INSTRUMENTATIONS="mysql2,redis,faraday"
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Disable specific instrumentations:**

```console
export OTEL_RUBY_INSTRUMENTATION_SINATRA_ENABLED="false"
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Configure instrumentation options:**

```console
export OTEL_RUBY_ENABLED_INSTRUMENTATIONS="redis"
export OTEL_RUBY_INSTRUMENTATION_REDIS_CONFIG_OPTS="peer_service=new_service;db_statement=omit"
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### Non-Rails Frameworks (Sinatra, Rackup, etc.)

For frameworks that don't automatically call `Bundler.require`, enable it explicitly:

```console
export OTEL_RUBY_REQUIRE_BUNDLER="true"
RUBYOPT="-r opentelemetry-auto-instrumentation" rackup config.ru
```

### Advanced: Loading External Gems

If you need to load gems outside your Gemfile (and have them instrumented), preload them before the auto-instrumentation:

```console
RUBYOPT="-r mysql2 -r faraday -r opentelemetry-auto-instrumentation" ruby application.rb
```

## Troubleshooting

### How Auto-Instrumentation Works

The gem works by patching `Bundler::Runtime#require` to inject OpenTelemetry initialization when gems are loaded. Rails applications call `Bundler.require` automatically during boot, so they work seamlessly. Other frameworks (like Sinatra) may require manual configuration.

**Solution:** For non-Rails frameworks, either:

- Call `Bundler.require` explicitly in your code, OR
- Set `OTEL_RUBY_REQUIRE_BUNDLER=true` environment variable

### Instrumentation Timing Issues

Instrumentation is only applied when gems are loaded through `Bundler.require`. If you require a library **after** `Bundler.require` has been called, it won't be instrumented.

**Example of what doesn't work:**

```ruby
# app.rb
Bundler.require
require 'faraday'  # Loaded too late - won't be instrumented
```

**Solution:** Preload the gem via `RUBYOPT`:

```console
RUBYOPT="-r faraday -r opentelemetry-auto-instrumentation" ruby application.rb
```

This ensures gems are loaded early enough for instrumentation to be applied.

### Dependency Version Conflicts

The auto-instrumentation gem loads OpenTelemetry components into Ruby's `$LOAD_PATH`. It also includes two non-OpenTelemetry dependencies required for OTLP exporters:

- `google-protobuf`
- `googleapis-common-protos-types`

**Problem:** If your Gemfile includes different versions of these gems, you may encounter version conflicts.

**Solution:** If you experience protobuf-related errors:

1. Remove `google-protobuf` and `googleapis-common-protos-types` from your Gemfile
2. Let `opentelemetry-auto-instrumentation` manage these dependencies
3. In most cases, version mismatches won't cause issues, but this is the safest approach

### Using with bundle exec

Since the gem is installed via `gem install` (not in your Gemfile), you may need to specify the full path when using `bundle exec`:

```console
RUBYOPT="-r /path/to/gems/opentelemetry-auto-instrumentation-X.X.X/lib/opentelemetry-auto-instrumentation" bundle exec rails server
```

Find the path using: `gem which opentelemetry-auto-instrumentation`

## Example

See [example/README.md](example/README.md)

## Configuration

The following environment variables are specific to this gem (not standard OpenTelemetry variables):

| Environment Variable | Description | Example |
| ---------------------- | ----------- | ------- |
| `OTEL_RUBY_REQUIRE_BUNDLER` | Set to `true` to automatically call `Bundler.require` during initialization. Required for frameworks that don't call it automatically (e.g., Sinatra). | `true` |
| `OTEL_RUBY_RESOURCE_DETECTORS` | Comma-separated list of resource detectors. Supported: `container`, `azure`, `aws`. **Note:** GCP detector not supported due to additional dependencies. | `container,azure,aws` |
| `OTEL_RUBY_ENABLED_INSTRUMENTATIONS` | Only load specific instrumentations (comma-separated). Omit to load all available. | `redis,mysql2,faraday` |
| `OTEL_RUBY_ADDITIONAL_GEM_PATH` | Custom gem installation path for OpenTelemetry Operator environments. | `/custom/gem/path` |
| `OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG` | Set to `true` for debug output during initialization. | `true` |
| `OTEL_RUBY_UNLOAD_LIBRARY` | Prevent specific gems from being preloaded (e.g., `google-protobuf`). | `google-protobuf` |

## How can I get involved?

The `opentelemetry-auto-instrumentation` gem source is on GitHub, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-auto-instrumentation` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[opentelemetry-operator]: https://github.com/open-telemetry/opentelemetry-operator
