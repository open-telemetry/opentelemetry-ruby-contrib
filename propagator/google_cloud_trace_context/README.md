# opentelemetry-propagator-google_cloud_trace_context

The `opentelemetry-propagator-google_cloud_trace_context` gem contains injectors and extractors for the
[Google Cloud X-Cloud-Trace-Context format][gcp-spec].

## X-Cloud-Trace-Context header

The `X-Cloud-Trace-Context` header that is used by Google Cloud predates the W3C specification. For backwards compatibility, some Google Cloud services continue to accept, generate, and propagate the `X-Cloud-Trace-Context` header. However, it is likely that these systems also support the traceparent header.

For example Google's Cloud Load Balancers (which do not support the traceparent header)[https://issuetracker.google.com/issues/253419736], instead will only propagate `X-Cloud-Trace-Context` which this gem helps resolve.

The `X-Cloud-Trace-Context` header has the following format:

```yaml
X-Cloud-Trace-Context: TRACE_ID/SPAN_ID;o=OPTIONS
```

The fields of header are defined as follows:

- `TRACE_ID` is a 32-character hexadecimal value representing a 128-bit number.
- `SPAN_ID` is a 64-bit decimal representation of the unsigned span ID.
- `OPTIONS` supports 0 (parent not sampled) and 1 (parent was sampled).

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-propagator-google_cloud_trace_context
```

Or, if you use [bundler][bundler-home], include `opentelemetry-propagator-google_cloud_trace_context` in your `Gemfile`.

Configure your application to use this propagator by setting the following [environment variable][envars]:

```console
OTEL_PROPAGATORS=google_cloud_trace_context
```

## How can I get involved?

The `opentelemetry-propagator-google_cloud_trace_context` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-propagator-google_cloud_trace_context` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[gcp-spec]: https://cloud.google.com/appengine/docs/standard/writing-application-logs
[rfc7230-url]: https://tools.ietf.org/html/rfc7230#section-3.2
[fields-spec-url]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/context/api-propagators.md#fields
[envars]: https://github.com/open-telemetry/opentelemetry-specification/blob/v1.20.0/specification/sdk-environment-variables.md#general-sdk-configuration
