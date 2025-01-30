# OpenTelemetry Instrumentation Test Helpers: Metrics

This Ruby gem facilitates testing instrumentation libraries with respect to the OpenTelemetry Metrics API and SDK.

## Usage

Add the gem to your instrumentation's Gemfile:

```ruby
# Gemfile

group :test, :development do
  gem 'opentelemetry-metrics-test-helpers', path: '../../helpers/metrics-test-helpers', require: false
end
```

It's not necessary to add this gem as a development dependency in the gemspec.
`opentelemetry-metrics-test-helpers` is not currently published to RubyGems,
and it is expected that it will always be bundled from the source in this
repository.

Note that metrics-test-helpers makes no attempt to require
the metrics API or SDK. It is designed to work with or without the metrics API and SDK defined, but you may experience issues if the API or SDK gem is in the gemfile but not yet loaded when the test helpers are initialized.

## Examples

In a test_helper.rb, after the `configure` block,
require this library:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.add_span_processor span_processor
end
require 'opentelemetry-metrics-test-helpers'
```

If the library uses Appraisals, it is recommended to appraise with and without the metrics api and sdk gems. Note that any metrics implementation in instrumentation libraries should be written against the API only, but for testing the SDK is required to collect metrics data - testing under all three scenarios (no metrics at all, api only, and with the sdk) helps ensure compliance with this requirement.

In a test:

```ruby
with_metrics_sdk do
  let(:metric_snapshots) do
    metrics_exporter.tap(&:pull)
      .metric_snapshots.select { |snapshot| snapshot.data_points.any? }
      .group_by(&:name)
  end

  it "uses metrics", with_metrics_sdk: true do
    # do something here ...
    _(metric_snapshots).count.must_equal(4)
  end
end
```

- `metrics_exporter` is automatically reset before each test.
- `#with_metrics_sdk` will only yield if the SDK is present.
- `#with_metrics_api` will only yield if the API is present

## How can I get involved?

The `opentelemetry-metrics-test-helpers` gem source is [on github][repo-github], along with related gems including `opentelemetry-instrumentation-pg` and `opentelemetry-instrumentation-trilogy`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-helpers-sql-obfuscation` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
