# OpenTelemetry Auto Instrumentation

The `opentelemetry-auto-instrumentation` gem provides automatic loading and initialization of the OpenTelemetry Ruby SDK for zero-code instrumentation of your applications.

## Table of Contents

- [What is OpenTelemetry?](#what-is-opentelemetry)
- [How does this gem fit in?](#how-does-this-gem-fit-in)
- [Getting Started](#getting-started)
- [Telemetry Signals](#telemetry-signals)
  - [Traces](#traces)
  - [Metrics](#metrics)
  - [Logs](#logs)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Example](#example)
- [How can I get involved?](#how-can-i-get-involved)
- [License](#license)

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework that provides a unified API, SDK, and tooling for instrumenting cloud-native applications. It captures distributed traces, metrics, and logs from your application, which can be analyzed using observability backends like Prometheus, Jaeger, and others.

## How does this gem fit in?

This gem enables OpenTelemetry instrumentation without modifying your application code. It automatically:

- Loads the OpenTelemetry SDK (traces, metrics, and logs)
- Initializes instrumentations for detected libraries
- Configures OTLP exporters for all three signals
- Optionally configures resource detectors

This gem is particularly useful with the [OpenTelemetry Operator][opentelemetry-operator] for Kubernetes environments.

## Getting Started

Install the gem:

```console
gem install opentelemetry-auto-instrumentation
```

**Note:** Install via `gem install` rather than adding to your Gemfile, as this gem needs to load before your application starts.

Then instrument any Ruby application:

```console
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

For Rails (which calls `Bundler.require` automatically):

```console
RUBYOPT="-r opentelemetry-auto-instrumentation" rails server
```

For other frameworks (Sinatra, Rackup, etc.) that don't call `Bundler.require` automatically:

```console
OTEL_RUBY_REQUIRE_BUNDLER=true RUBYOPT="-r opentelemetry-auto-instrumentation" rackup config.ru
```

### What gets installed?

Installing `opentelemetry-auto-instrumentation` automatically includes:

```console
opentelemetry-sdk
opentelemetry-api
opentelemetry-instrumentation-all
opentelemetry-exporter-otlp
opentelemetry-exporter-otlp-metrics
opentelemetry-exporter-otlp-logs
opentelemetry-helpers-mysql
opentelemetry-helpers-sql-processor
opentelemetry-resource-detector-azure
opentelemetry-resource-detector-container
opentelemetry-resource-detector-aws
```

## Telemetry Signals

By default, this gem sets up **traces, metrics, and logs** and exports all three to an OTLP endpoint (`http://localhost:4318`). Each signal can be configured or disabled independently via standard OpenTelemetry environment variables.

### Traces

Traces are enabled by default using the OTLP exporter. See the [opentelemetry-sdk README][otel-sdk-readme] for full configuration options.

**Disable traces:**

```console
OTEL_TRACES_EXPORTER=none RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Custom endpoint:**

```console
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://my-collector:4318/v1/traces \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### Metrics

Metrics are enabled by default using the OTLP metrics exporter. See the [opentelemetry-metrics-sdk README][otel-metrics-sdk-readme] for full configuration options.

**Disable metrics:**

```console
OTEL_METRICS_EXPORTER=none RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Custom endpoint:**

```console
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://my-collector:4318/v1/metrics \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### Logs

Logs are enabled by default using the OTLP logs exporter. See the [opentelemetry-logs-sdk README][otel-logs-sdk-readme] for full configuration options.

**Disable logs:**

```console
OTEL_LOGS_EXPORTER=none RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Custom endpoint:**

```console
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://my-collector:4318/v1/logs \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

### Disable all signals except traces

```console
OTEL_METRICS_EXPORTER=none OTEL_LOGS_EXPORTER=none \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

## Usage

**Send all signals to a collector with a service name:**

```console
export OTEL_EXPORTER_OTLP_ENDPOINT="http://my-collector:4318"
export OTEL_SERVICE_NAME="my-service"
RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Enable only specific instrumentations:**

```console
OTEL_RUBY_ENABLED_INSTRUMENTATIONS="mysql2,redis" \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Disable a specific instrumentation:**

```console
OTEL_RUBY_INSTRUMENTATION_SINATRA_ENABLED=false \
  RUBYOPT="-r opentelemetry-auto-instrumentation" ruby application.rb
```

**Preload gems that need to be instrumented but aren't in your Gemfile:**

```console
RUBYOPT="-r faraday -r opentelemetry-auto-instrumentation" ruby application.rb
```

**Using with `bundle exec`** (when the gem is installed outside the bundle):

```console
RUBYOPT="-r $(gem which opentelemetry-auto-instrumentation)" bundle exec rails server
```

## Configuration

The following environment variables are specific to this gem (not standard OpenTelemetry variables):

| Environment Variable | Description | Example |
| -------------------- | ----------- | ------- |
| `OTEL_RUBY_REQUIRE_BUNDLER` | Set to `true` to automatically call `Bundler.require` during initialization. Required for frameworks that don't call it automatically (e.g., Sinatra). | `true` |
| `OTEL_RUBY_RESOURCE_DETECTORS` | Comma-separated list of resource detectors. Supported: `container`, `azure`, `aws`. **Note:** The GCP detector is not included — its `google-cloud-env` dependency makes blocking HTTP requests to the GCP metadata server, causing timeouts in non-GCP environments. | `container,azure,aws` |
| `OTEL_RUBY_ENABLED_INSTRUMENTATIONS` | Only load specific instrumentations (comma-separated). Omit to load all available. | `redis,mysql2,faraday` |
| `OTEL_RUBY_ADDITIONAL_GEM_PATH` | Custom gem installation path for OpenTelemetry Operator environments. | `/custom/gem/path` |
| `OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG` | Set to `true` for debug output during initialization. | `true` |
| `OTEL_RUBY_UNLOAD_LIBRARY` | Prevent specific gems from being preloaded (e.g., `google-protobuf`). | `google-protobuf` |

For standard OpenTelemetry environment variables (exporters, endpoints, resource attributes, etc.), refer to the SDK READMEs:

- [opentelemetry-sdk (traces)][otel-sdk-readme]
- [opentelemetry-metrics-sdk (metrics)][otel-metrics-sdk-readme]
- [opentelemetry-logs-sdk (logs)][otel-logs-sdk-readme]

## Troubleshooting

### How Auto-Instrumentation Works

The gem patches `Bundler::Runtime#require` to inject OpenTelemetry initialization when gems are loaded. Rails calls `Bundler.require` automatically during boot; other frameworks need `OTEL_RUBY_REQUIRE_BUNDLER=true`.

### Instrumentation Timing Issues

Instrumentation is only applied to libraries loaded through `Bundler.require`. If you require a library after `Bundler.require` has already been called, it won't be instrumented. Preload it via `RUBYOPT` instead:

```console
RUBYOPT="-r faraday -r opentelemetry-auto-instrumentation" ruby application.rb
```

### Dependency Version Conflicts

This gem loads OpenTelemetry components (including `google-protobuf` and `googleapis-common-protos-types`) directly into `$LOAD_PATH`. If your Gemfile pins different versions of these gems, you may encounter conflicts. Remove them from your Gemfile and let this gem manage them.

## Example

See [example/README.md](example/README.md)

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
[otel-sdk-readme]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/sdk
[otel-metrics-sdk-readme]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/metrics_sdk
[otel-logs-sdk-readme]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/logs_sdk
