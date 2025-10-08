# OpenTelemetry Logger Instrumentation

The Logger instrumentation is a community-maintained bridge for the Ruby [logger][logger-home] standard library.

## How do I get started?

Install the gem using:

```shell
gem install opentelemetry-instrumentation-logger
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-logger` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Logger'
end
```

Alternatively, you can call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the `./example/logger.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/logger/example/logger.rb)

## Development

The test suite leverages [appraisal][appraisal] to verify the integration across multiple Rails versions. To run the tests with appraisal:

```shell
cd instrumentation/logger
bundle exec appraisal generate
bundle exec appraisal install
bundle exec appraisal rake test
```

## How can I get involved?

The `opentelemetry-instrumentation-logger` gem source is [on github][repo-github], along with related gems including `opentelemetry-logs-api` and `opentelemetry-logs-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-logger` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[appraisal]: https://github.com/thoughtbot/appraisal
[bundler-home]: https://bundler.io
[logger-home]: https://github.com/ruby/logger
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
