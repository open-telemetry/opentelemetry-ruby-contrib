# opentelemetry-sampler-xray

The `opentelemetry-sampler-xray` gem contains the AWS X-Ray Remote Sampler for OpenTelemetry.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-sampler-xray
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sampler-xray` in your `Gemfile`.

In your application:

```ruby
OpenTelemetry.tracer_provider.sampler = OpenTelemetry::Sampler::XRay::AwsXRayRemoteSampler.new(
    polling_interval: 300, resource: OpenTelemetry::SDK::Resources::Resource.create({
        "service.name"=>"my-service-name",
        "cloud.platform"=>"aws_ec2"
    })
)
```

## How can I get involved?

The `opentelemetry-sampler-xray` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-sampler-xray` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[aws-xray]: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
