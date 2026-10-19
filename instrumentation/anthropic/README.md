# OpenTelemetry Anthropic Instrumentation

The Anthropic instrumentation is a community-maintained instrumentation for the [Anthropic][anthropic-home] gem.

## Anthropic 0.39.0+ Native Integration

Anthropic 0.39.0+ includes native OpenTelemetry instrumentation. For the best experience and continued support, we recommend:

- **Anthropic < 0.39.0**: Use `opentelemetry-instrumentation-anthropic` gem
- **Anthropic ≥ 0.39.0**: Use Anthropic's built-in OpenTelemetry support (remove `opentelemetry-instrumentation-anthropic` gem)

Community instrumentation is compatible with Anthropic versions up to 0.38.x. Development of this gem is frozen for newer Anthropic versions in favor of the native integration.

Learn more in the [anthropic documentation](https://platform.claude.com/docs/en/manage-claude/opentelemetry/sdk).

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-anthropic
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-anthropic` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Anthropic'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## How can I get involved?

The `opentelemetry-instrumentation-anthropic` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-anthropic` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[anthropic-home]: https://github.com/anthropics/anthropic-sdk-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
