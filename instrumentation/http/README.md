# OpenTelemetry Http Instrumentation

The HTTP instrumentation is a community-maintained instrumentation for the [HTTP][http-home] gem.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-http
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-http` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::HTTP'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Enriching http span names

We surface a hook to easily rename your span.

The lambda accepts as arguments (request_method, request_path) and returns a string that is set as the span name.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack', { span_name_formatter: ->(request_method, request_path) { "HTTP #{request_method} #{request_path}" }
end
```

## Examples

Example usage can be seen in the [`./example/trace_demonstration.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/http/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-http` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-http` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[http-home]: https://github.com/httprb/http
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
