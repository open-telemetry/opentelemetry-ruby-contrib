# OpenTelemetry RubyKafka Instrumentation

The RubyKafka instrumentation is a community-maintained instrumentation for [RubyKafka][ruby_kafka-home], a client library for Apache Kafka.

> [!IMPORTANT]
>
> **Deprecation Notice:**
> This gem is deprecated due to the upstream dependency it relies on no longer being maintained. The code remains available for reference, but no further updates or fixes will be provided. Users should consider migrating to actively supported alternatives.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-ruby_kafka
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-ruby_kafka` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::RubyKafka'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the [`./example/ruby_kafka.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/ruby_kafka/example/ruby_kafka.rb)

## How can I get involved?

The `opentelemetry-instrumentation-ruby_kafka` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

### Running Tests

Tests in this package require a running instance of Kafka and Zookeeper, which are made available via `docker-compose`:

```bash
ruby-kafka $> docker-compose up -d kafka
 Creating network "ruby_kafka_default" with the default driver
 Creating ruby_kafka_zookeeper_1 ... done
 Creating ruby_kafka_kafka_1     ... done
```

The run tests using `rake`

```bash
ruby-kafka $> bundle exec rake test
```

To stop the dependent services

```bash
ruby-kafka $> docker-compose down
```

## License

The `opentelemetry-instrumentation-ruby_kafka` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[ruby_kafka-home]: https://github.com/zendesk/ruby-kafka
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
