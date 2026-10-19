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

The `opentelemetry-sampler-xray` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-sampler-xray` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
