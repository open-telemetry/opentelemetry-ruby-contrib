# OpenTelemetry Shoryuken Instrumentation

The Shoryuken instrumentation is a community-maintained instrumentation for the [Shoryuken][shoryuken-home] Ruby jobs system.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-shoryuken
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-shoryuken` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Shoryuken'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

Note that span names can be configured to be based on either the queue name or the job class with the `span_naming` config option, as shown below. Valid values are `:queue` and `:job_class`, `:queue` being the default.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Shoryuken', span_naming: :queue
end
```

## Examples

Example usage can be seen in the `./example/shoryuken.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/shoryuken/example/shoryuken.rb)

## How can I get involved?

The `opentelemetry-instrumentation-shoryuken` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-shoryuken` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[shoryuken-home]: https://github.com/ruby-shoryuken/shoryuken
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
