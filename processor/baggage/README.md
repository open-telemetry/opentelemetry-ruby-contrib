# Baggage Span Processor

This is an OpenTelemetry [span processor](https://opentelemetry.io/docs/specs/otel/trace/sdk/#span-processor) that reads key/values stored in [Baggage](https://opentelemetry.io/docs/specs/otel/baggage/api/) in the starting span's parent context and adds them as attributes to the span.

Keys and values added to Baggage will appear on all subsequent child spans for a trace within this service *and* will be propagated to external services via propagation headers.
If the external services also have a Baggage span processor, the keys and values will appear in those child spans as well.

⚠️ Waning ⚠️
To repeat: a consequence of adding data to Baggage is that the keys and values will appear in all outgoing HTTP headers from the application.
Do not put sensitive information in Baggage.

## How do I get started?

Install the gem using:

```shell
gem install opentelemetry-processor-baggage
```

Or, if you use [bundler][bundler-home], include `opentelemetry-processor-baggage` to your `Gemfile`.

### Version Compatibility

* OpenTelemetry API v1.0+

## Usage

To install the instrumentation, add the gem to your Gemfile:

```ruby
gem 'opentelemetry-processor-baggage'
```

Then add the processor to an SDK's configuration:

```ruby
require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  # Add the BaggageSpanProcessor to the collection of span processors
  c.add_span_processor(OpenTelemetry::Processor::Baggage::BaggageSpanProcessor.new)

  # Because the span processor list is no longer empty, the SDK will not use the
  # values in OTEL_TRACES_EXPORTER to instantiate exporters.
  # You'll need to declare your own here in the configure block.
  #
  # These lines setup the default: a batching OTLP exporter.
  c.add_span_processor(
    # these constructors without arguments will pull config from the environment
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new()
    )
  )
end
```

## How can I get involved?

The `opentelemetry-processor-baggage` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-sinatra` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
