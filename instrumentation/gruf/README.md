# OpenTelemetry Gruf Instrumentation

The OpenTelemetry Gruf Ruby gem is a community-maintained instrumentation for Gruf, a gRPC framework for Ruby. It enables automatic tracing of RPC requests handled by Gruf services.

## Overview

This instrumentation integrates OpenTelemetry with Gruf to create spans for incoming gRPC requests. It helps in observing request flow, latency and errors in distributed systems.

## How it works

The Gruf instrumentation hooks into the request lifecycle of Gruf-based gRPC services and automatically creates spans for each incoming RPC request.

It captures useful metadata such as:
- RPC method name
- Request lifecycle events
- Errors, if any

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-gruf
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-gruf` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Gruf', {
    peer_service: "Example",
    grpc_ignore_methods_on_client: [],
    grpc_ignore_methods_on_server: [],
    allowed_metadata_headers: [],
  }
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Key Files

- `instrumentation.rb` — Entry point for enabling the instrumentation
- `middleware/` — Contains logic for intercepting and tracing requests
- `version.rb` — Defines the gem version

## Examples

Example usage can be seen in the [`./example/trace_demonstration.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/gruf/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-gruf` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-gruf` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
