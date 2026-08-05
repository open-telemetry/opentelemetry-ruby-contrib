# OpenTelemetry::Resource::Detector::OS

The `opentelemetry-resource-detector-os` gem provides an OS resource detector for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detector-os` gem provides a means of retrieving a resource for supported environments following the resource semantic conventions. This detector automatically identifies and populates resource attributes with relevant metadata from the environment.

## Installation

Install the gem using:

```console
gem install opentelemetry-sdk
gem install opentelemetry-resource-detector-os
```

Or, if you use Bundler, include `opentelemetry-sdk` and `opentelemetry-resource-detector-os` in your `Gemfile`.

## Usage

```rb
require 'opentelemetry/sdk'
require 'opentelemetry/resource/detector'

OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detector::OS.detect
end
```

This will populate the following resource attributes:

- `os.type`
- `os.description`
- `os.name`
- `os.version`

## License

The `opentelemetry-resource-detector-os` gem is distributed under the Apache 2.0 license. See LICENSE for more information.
