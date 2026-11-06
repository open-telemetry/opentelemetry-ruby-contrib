# OpenTelemetry Redis Instrumentation

The OpenTelemetry Redis Ruby gem is a community maintained instrumentation for [Redis][redis-home]. This is an in-memory data store that is used as a database, cache, and message broker.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-redis
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-redis` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

The Redis instrumentation allows the user to supply additional attributes via context propagation. This may be used to propagate attributes from instrumentation for things like Resque and Sidekiq, for example, to attach to the Redis client spans.

```ruby
require 'opentelemetry/instrumentation/redis'

redis = ::Redis.new
OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'cache') do
  redis.set('K', 'x')
end
```

###  Configuration options

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis', {
    # The obfuscation of arguments in the db.statement attribute is enabled by default.
    # To include the full query, set db_statement to :include.
    # To obfuscate, set db_statement to :obfuscate.
    # To omit the attribute, set db_statement to :omit.
    db_statement: :include,
  }
end
```

## Example

An example of usage can be seen in [`example/redis.rb`](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/redis/example/redis.rb).

## Development

You'll need Redis installed locally to run the test suite. Once you've
installed it, it will start and stop automatically when you run `rake`.

## How can I get involved?

The `opentelemetry-instrumentation-redis` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[redis-home]: https://redis.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
