# OpenTelemetry::Resource::Detector::GoogleCloudPlatform

The `opentelemetry-resource-detector-google_cloud_platform` gem provides a Google Cloud Platform resource detector for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detector-google_cloud_platform` gem provides a means of retrieving a resource for supported environments following the resource semantic conventions.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-resource-detector-google_cloud_platform
```

Or, if you use Bundler, include `opentelemetry-sdk` and `opentelemetry-resource-detector-google_cloud_platform` in your `Gemfile`.

```rb
require 'opentelemetry/sdk'
require 'opentelemetry/resource/detector'

OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detector::GoogleCloudPlatform.detect
end
```


This will populate the following resource attributes for compute running on Google Cloud Platform:

* Compute Engine:
* * `cloud.provider`
* * `cloud.account.id`
* * `cloud.region`
* * `cloud.availability_zone`
* * `host.id`
* * `host.name`

* Google Kubernetes Engine:
* * `k8s.cluster.name`
* * `k8s.namespace.name`
* * `k8s.pod.name`
* * `k8s.node.name`
* * `container.name`

* Google Cloud Run:
* * `cloud.provider`
* * `cloud.account.id`
* * `cloud.region`
* * `cloud.availability_zone`
* * `faas.name`
* * `faas.version`

## How can I get involved?

The `opentelemetry-resource-detector-google_cloud_platform` gem source is on GitHub, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the meeting calendar for dates and times. For more information on this and other language SIGs, see the OpenTelemetry community page.

## License

The `opentelemetry-resource-detector-google_cloud_platform` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/discussions
[k8sattributesprocessor-url]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/k8sattributesprocessor/README.md