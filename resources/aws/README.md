# OpenTelemetry::Resource::Detector::AWS

The `opentelemetry-resource-detector-aws` gem provides an AWS resource detector for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detector-aws` gem provides a means of retrieving a resource for supported environments following the resource semantic conventions. When running on AWS platforms, this detector automatically identifies and populates resource attributes with relevant metadata from the environment.

## Installation

Install the gem using:

```console
gem install opentelemetry-sdk
gem install opentelemetry-resource-detector-aws
```

Or, if you use Bundler, include `opentelemetry-sdk` and `opentelemetry-resource-detector-aws` in your `Gemfile`.

## Usage

```rb
require 'opentelemetry/sdk'
require 'opentelemetry/resource/detector'

OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detector::AWS.detect
end
```

## Supported AWS Platforms

### AWS EC2 Detector

Populates `cloud` and `host` for processes running on Amazon EC2, including abstractions such as ECS on EC2. Notably, it does not populate anything on AWS Fargate.

| Resource Attribute | Description |
|--------------------|-------------|
| `cloud.account.id` | Value of `accountId` from `/latest/dynamic/instance-identity/document` request |
| `cloud.availability_zone` | Value of `availabilityZone` from `/latest/dynamic/instance-identity/document` request |
| `cloud.platform` | The cloud platform. In this context, it's always "aws_ec2" |
| `cloud.provider` | The cloud provider. In this context, it's always "aws" |
| `cloud.region` | Value of `region` from `/latest/dynamic/instance-identity/document` request |
| `host.id` | Value of `instanceId` from `/latest/dynamic/instance-identity/document` request |
| `host.name` | Value of hostname from `/latest/meta-data/hostname` request |
| `host.type` | Value of `instanceType` from `/latest/dynamic/instance-identity/document` request |

Additional AWS platforms (ECS, EKS, Lambda) will be supported in future versions.

## License

The `opentelemetry-resource-detector-aws` gem is distributed under the Apache 2.0 license. See LICENSE for more information.
