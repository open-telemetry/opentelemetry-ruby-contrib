# OpenTelemetry Sidekiq Instrumentation

The Sidekiq instrumentation is a community-maintained instrumentation for the [Sidekiq][sidekiq-home] Ruby jobs system.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-sidekiq
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-sidekiq` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sidekiq'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Configuration Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `span_naming` | `:queue` | How job spans are named. `:queue` uses the queue name and operation (for example `default process`), `:job_class` uses the job class and operation (for example `SimpleJob process`). |
| `propagation_style` | `:link` | How the job's trace relates to the span that enqueued it. `:link` starts a new trace whose first span links to the enqueuing span, `:child` makes the job a child of the enqueuing span in the same trace, `:none` starts a new trace with no relationship. |
| `trace_launcher_heartbeat` | `false` | Traces the `Sidekiq::Launcher` heartbeat. |
| `trace_poller_enqueue` | `false` | Traces `Sidekiq::Scheduled::Poller#enqueue`. |
| `trace_poller_wait` | `false` | Traces `Sidekiq::Scheduled::Poller#wait`. |
| `trace_processor_process_one` | `false` | Traces `Sidekiq::Processor#process_one` and `Sidekiq::Processor#fetch`. |

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sidekiq', {
    span_naming: :job_class,
    propagation_style: :child,
  }
end
```

## Examples

Example usage can be seen in the [`./example/sidekiq.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/sidekiq/example/sidekiq.rb)

## Development

You'll need Redis installed locally to run the test suite. Once you've
installed it, it will start and stop automatically when you run `rake`.

```console
redis-server test/redis.conf
```

## How can I get involved?

The `opentelemetry-instrumentation-sidekiq` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-sidekiq` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[sidekiq-home]: https://github.com/mperham/sidekiq
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
