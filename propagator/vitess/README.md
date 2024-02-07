# opentelemetry-propagator-vitess

The `opentelemetry-propagator-vitess` gem contains injectors and extractors for the
[Vitess context propagation format][vitess-spec].

## Vitess trace context Format

Vitess encodes trace context in a special SQL comment style. The format is a base64 string encoding of a JSON object that, at it simplest, looks something like this:

```json
{"uber-trace-id":"{trace-id}:{span-id}:{parent-span-id}:{flags}"}
```

To inform Vitess of the trace context, the context is prepended to a SQL query, e.g.:

```sql
/*VT_SPAN_CONTEXT=<base64 value>*/ SELECT * from product;
```

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation. It is intended to be used with SQL client instrumentation, such as the `opentelemetry-instrumentation-trilogy` gem.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-propagator-vitess
```

Or, if you use [bundler][bundler-home], include `opentelemetry-propagator-vitess` in your `Gemfile`.

Configure your application to use this propagator with the Trilogy client instrumentation by setting the following [environment variable][envars]:

```
OTEL_RUBY_INSTRUMENTATION_TRILOGY_PROPAGATOR=vitess
```

## How can I get involved?

The `opentelemetry-propagator-vitess` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-propagator-vitess` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[vitess-spec]: https://vitess.io/docs/16.0/user-guides/configuration-advanced/tracing/#instrumenting-queries
[envars]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md#general-sdk-configuration
