# Zero-code Instrumentation

The `zero-code-instrumentation` gem provides an easy way to load and initialize opentelemetry-ruby for zero-code instrumentation.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `zero-code-instrumentation` gem provides an easy way to load and initialize the OpenTelemetry Ruby SDK without changing your code initialize the SDK. This gem is particularly used with the [OpenTelemetry Operator][opentelemetry-operator].

## How do I get started?

It's recommended to install this gem through gem install rather than Bundler since it doesn't require modifying any user's codebase (including the Gemfile).

Install the gem using:

```console
gem install zero-code-instrumentation
```

Install zero-code-instrumentation will automatically install following gems:
```console
opentelemetry-sdk
opentelemetry-api
opentelemetry-instrumentation-all
opentelemetry-exporter-otlp
opentelemetry-helpers-mysql
opentelemetry-helpers-sql-obfuscation
opentelemetry-resource-detector-google_cloud_platform
opentelemetry-resource-detector-azure
opentelemetry-resource-detector-container
```

Instrument your application:

```console
RUBYOPT="-r zero-code-instrumentation" ruby application.rb
```

Instrument your application with additional environment variables:

```console
export OTEL_TRACES_EXPORTER="otlp"
export OTEL_EXPORTER_OTLP_ENDPOINT="your-endpoint"
export OTEL_RUBY_RESOURCE_DETECTORS="container"
export OTEL_SERVICE_NAME="your-service-name"

RUBYOPT="-r zero-code-instrumentation" ruby application.rb
```

Instrument your application with disabling certain instrumentation (e.g. sinatra):

```console
export OTEL_RUBY_INSTRUMENTATION_SINATRA_ENABLED='false'
RUBYOPT="-r zero-code-instrumentation" ruby application.rb
```

Instrument your application with only certain instrumentation installed (e.g. mysql, redis):

```console
export OTEL_RUBY_ENABLED_INSTRUMENTATIONS='mysql2,redis'
RUBYOPT="-r zero-code-instrumentation" ruby application.rb
```

Instrument your application with only redis and configure its options:

```console
export OTEL_RUBY_ENABLED_INSTRUMENTATIONS='redis'
export OTEL_RUBY_INSTRUMENTATION_REDIS_CONFIG_OPTS='peer_service=new_service;db_statement=omit'
RUBYOPT="-r zero-code-instrumentation" ruby application.rb
```

Instrument Rails application:

```console
RUBYOPT="-r zero-code-instrumentation" rails server
```

Instrument Rails application with `bundle exec`

Since installing the `zero-code-instrumentation` gem through `gem install`, anything related to the OpenTelemetry gem won't be stored in Bundler's gem path. Therefore, users need to add an additional gem path that contains these gems prior to initialization.

```console
RUBYOPT="-r {PUT YOUR GEM PATH}/gems/zero-code-instrumentation-0.1.0/lib/zero-code-instrumentation" bundle exec rails server
```

Instrument Sinatra application with rackup:

If you are using a Gemfile to install the required gems but without `Bundler.require`, set `REQUIRE_BUNDLER` to true. This way, `zero-code-instrumentation` will call `Bundler.require` to initialize the required gems prior to SDK initialization.

```console
export REQUIRE_BUNDLER=true
RUBYOPT="-r zero-code-instrumentation" rackup config.ru
```

If you wish to load some gems outside the Gemfile, then they need to be placed in front of zero-code-instrumentation:

```console
export BUNDLE_WITHOUT=development,test
gem install mysql2
RUBYOPT="-r mysql2 -r zero-code-instrumentation" ruby application.rb
```

## Example

In example folder, execute the following commands should see the trace output.

```console
# if user don't want to install zero-code-instrumentation from rubygems.org
# user can build the gem and install it with gem install *.gem

gem install zero-code-instrumentation
bundle install
export REQUIRE_BUNDLER=true
export OTEL_TRACES_EXPORTER=console
RUBYOPT="-r zero-code-instrumentation" ruby app.rb
```

## Configuration

These environment variables are not standard OpenTelemetry environment variables; they are only feature flags for this gem.

| Environment Variable | Description | Default | Example |
|----------------------|-------------|---------|---------|
| `REQUIRE_BUNDLER` | Set to `true` if you are using Bundler to install gems but without `Bundler.require` in your script during initialization. | nil | N/A |
| `USE_BUNDLE_EXEC` | Set to `true` if initializing through `bundle exec`. | nil | N/A |
| `ADDITIONAL_GEM_PATH` | Intended to be used for the OpenTelemetry Operator environment if you install `zero-code-instrumentation` to a customized path. | nil | N/A |
| `OTEL_OPERATOR` | Set to `true` to set the binding path for the OpenTelemetry Operator. | `/otel-auto-instrumentation-ruby` | N/A |
| `OTEL_RUBY_RESOURCE_DETECTORS` | Determine what kind of resource detector is needed. Currently supports `container`, `azure`, and `google_cloud_platform`. Use commas to separate multiple detectors. | nil | `container,azure` |
| `OTEL_RUBY_ENABLED_INSTRUMENTATIONS` | Shortcut used when you only want to instrument one or a couple of particular libraries. | nil | `redis,active_record` |
| `ZERO_CODE_DEBUG` | Set to `true` if want to see some debug information. This to avoid preload logger gem | nil | N/A |

## How can I get involved?

The `zero-code-instrumentation` gem source is on GitHub, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `zero-code-instrumentation` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[opentelemetry-operator]: https://github.com/open-telemetry/opentelemetry-operator
