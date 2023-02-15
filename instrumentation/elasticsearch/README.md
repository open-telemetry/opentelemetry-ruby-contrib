# OpenTelemetry Elasticsearch Instrumentation

The Elasticsearch instrumentation is a community-maintained instrumentation for the [elasticsearch][elasticsearch-home] gem.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-elasticsearch
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-elasticsearch` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Elasticsearch'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

To run the example:

1. Start Elasticsearch using docker-compose
    * `docker-compose up elasticsearch`
2. In a separate terminal window, `cd` to the examples directory and install gems
    * `cd example`
    * `bundle install`
3. Run the sample client script
    * `ruby elasticsearch.rb`

This will run a few Elasticsearch commands, printing OpenTelemetry traces to the console as it goes.

## How can I get involved?

The `opentelemetry-instrumentation-elasticsearch` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-elasticsearch` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[elasticsearch-home]: https://github.com/elastic/elasticsearch-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
