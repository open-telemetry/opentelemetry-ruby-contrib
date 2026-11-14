# OpenTelemetry Http Instrumentation

The HTTP instrumentation is a community-maintained instrumentation for the [HTTP][http-home] gem.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-http
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-http` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::HTTP'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Enriching http span names

We surface a hook to easily rename your span.

The lambda accepts as arguments (request_method, request_path) and returns a string that is set as the span name.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack', { span_name_formatter: ->(request_method, request_path) { "HTTP #{request_method} #{request_path}" }
end
```

## Examples

Example usage can be seen in the [`./example/trace_demonstration.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/http/example/trace_demonstration.rb)

## Metrics

This instrumentation can record the [`http.client.request.duration`](https://opentelemetry.io/docs/specs/semconv/http/http-metrics/#metric-httpclientrequestduration) histogram.

To record the metric, two things must be true:

- Stable HTTP semantic conventions are in use (it is not recorded in `old` or `http/dup` modes).
- A metrics SDK (such as `opentelemetry-metrics-sdk`) is installed and configured.

Requests to `untraced_hosts` or requests made in an untraced context are not measured.

Semantic conventions recommends using the following bucket boundaries: `[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]`. If your metrics SDK does not apply advisory parameters, configure a view with these boundaries.

| Attribute                   | Notes                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| `http.request.method`       | `_OTHER` for unknown methods                                                                      |
| `server.address`            |                                                                                                   |
| `server.port`               |                                                                                                   |
| `http.response.status_code` | When a response is received                                                                       |
| `network.protocol.version`  | When a response is received                                                                       |
| `error.type`                | The status code as a string for status codes outside 100–399, or the class name of a raised error |

## How can I get involved?

The `opentelemetry-instrumentation-http` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-http` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[http-home]: https://github.com/httprb/http
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk

## HTTP semantic convention stability

This instrumentation by default emits the stable HTTP semantic conventions. The `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable can be used to opt-in to the old or duplicate (both old and stable) semantic conventions.

When setting the value for `OTEL_SEMCONV_STABILITY_OPT_IN`, you can specify which conventions you wish to adopt:

- `http` - Emits the stable HTTP and networking conventions.
- `http/dup` - **DEPRECATED: Will be removed on April 15, 2026.** Emits both the old and stable HTTP and networking conventions.
- `old` - **DEPRECATED: Will be removed on April 15, 2026.** Emits the old HTTP and networking conventions.

For additional information on migration, please refer to our [documentation](https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/).
