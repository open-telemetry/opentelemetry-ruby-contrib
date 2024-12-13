# OpenTelemetry::Instrumentation::Grpc
> [!CAUTION]
> This gem is not ready for release by the open-telemetry org yet, but other versions are available on RubyGems

[![Gem Version](https://badge.fury.io/rb/opentelemetry-instrumentation-grpc.svg)](https://badge.fury.io/rb/opentelemetry-instrumentation-grpc)
[![GitHub Actions CI Status](https://github.com/hibachrach/opentelemetry-instrumentation-grpc/actions/workflows/main.yml/badge.svg)](https://github.com/hibachrach/opentelemetry-instrumentation-grpc/actions?query=branch%3Amain)

OpenTelemetry instrumentation for users of the `grpc` gem

> [!WARNING]
> Right now, the gem only instruments outbound requests to gRPC services

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
  $ bundle add opentelemetry-instrumentation-grpc
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
  $ gem install opentelemetry-instrumentation-grpc
```

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
  OpenTelemetry::SDK.configure do |c|
    c.use 'OpenTelemetry::Instrumentation::Grpc', {
      peer_service: "Example",
      allowed_metadata_headers: [],
    }
  end
```

Alternatively, you can also call `use_all` to install all the available
instrumentation.

```ruby
  OpenTelemetry::SDK.configure do |c|
    c.use_all
  end
```

## Development

Integration tests relay on a real gRPC server which is started by relevant tests. The proto definition is located in `test/support/proto/ping.proto`. Making changes to the proto definition requires re-creating grpc-generated code. To do this, run the following command:

```
bundle exec grpc_tools_ruby_protoc --ruby_out=. --grpc_out=. test/support/proto/ping.proto
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/open-telemetry/opentelemetry-ruby-contrib. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OpenTelemetry::Instrumentation::Grpc project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/CODE_OF_CONDUCT.md).
