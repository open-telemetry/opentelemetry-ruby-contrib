# OpenTelemetry Active Model Serializers Instrumentation

The OpenTelemetry Active Model Serializers gem is a community maintained instrumentation for [Active Model Serializers][active_model_serializers-home].

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-active_model_serializers
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-active_model_serializers` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveModelSerializers'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage of active_model_serializers can be seen [in the `./example/` folder](https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/active_model_serializers/example)

## How can I get involved?

The `opentelemetry-instrumentation-active_model_serializers` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[active_model_serializers-home]: https://github.com/rails-api/active_model_serializers
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
