# OpenTelemetry::Resource::Detector::Render

The `opentelemetry-resource-detector-render` gem provides a Render resource detector for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detector-render` gem provides a means of retrieving a resource for supported environments following the resource semantic conventions. When running on the Render platform, this detector automatically identifies and populates resource attributes with relevant metadata from the environment.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-sdk
gem install opentelemetry-instrumentation-render
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` and `opentelemetry-instrumentation-render` in your `Gemfile`.

## Usage

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/resource/detector'

OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detector::Render.detect
end
```

Populates `cloud`, `render` and `service` for processes running on Render.

| Resource Attribute | Description |
|--------------------|-------------|
| `cloud.provider` | The cloud provider. In this context, it's always "render" |
| `render.is_pull_request` | Value of the `IS_PULL_REQUEST` environment variable |
| `render.git.branch` | Value of the `RENDER_GIT_BRANCH` environment variable |
| `render.git.repo_slug` | Value of the `RENDER_GIT_REPO_SLUG` environment variable |
| `service.id` | Value of the `RENDER_SERVICE_ID` environment variable |
| `service.instance.id` | Value of the `RENDER_INSTANCE_ID` environment variable |
| `service.name` | Value of the `RENDER_SERVICE_NAME` environment variable |
| `service.version` | Value of the `RENDER_GIT_COMMIT` environment variable |

## How can I get involved?

The `opentelemetry-instrumentation-render` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-render` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
