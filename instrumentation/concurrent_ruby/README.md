# OpenTelemetry Concurrent Ruby Instrumentation

The OpenTelemetry Concurrent Ruby gem is a community maintained instrumentation for the [Concurrent Ruby][concurrent-ruby-home]. This is a concurrency toolkit inspired from various languages and classic concurrency patterns.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-concurrent_ruby
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-concurrent_ruby` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ConcurrentRuby'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## How can I get involved?

The `opentelemetry-instrumentation-concurrent_ruby` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[concurrent-ruby-home]: https://github.com/ruby-concurrency/concurrent-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
