# OpenTelemetry bunny Instrumentation

The bunny instrumentation is a community-maintained instrumentation for [bunny][bunny-home], a client library for RabbitMQ.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-bunny
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-bunny` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Bunny'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the [`./example/bunny.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/bunny/example/bunny.rb)

## How can I get involved?

The `opentelemetry-instrumentation-bunny` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-bunny` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bunny-home]: https://github.com/ruby-amqp/bunny
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
