# OpenTelemetry DelayedJob Instrumentation

The OpenTelemetry Delayed Job Ruby gem is a community maintained instrumentation for the [Delayed Job][delayedjob-home] Ruby jobs system.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-delayed_job
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-delayed_job` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::DelayedJob'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage of delayed_job can be seen in the [`./example/delayed_job.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/delayed_job/example/delayed_job.rb)

## How can I get involved?

The `opentelemetry-instrumentation-delayed_job` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[delayedjob-home]: https://github.com/collectiveidea/delayed_job
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
