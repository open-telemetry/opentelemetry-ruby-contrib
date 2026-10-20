# OpenTelemetry AWS-SDK Instrumentation

The OpenTelemetry `aws-sdk` gem is a community maintained instrumentation for [aws-sdk-ruby][aws-sdk-home].

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-aws_sdk
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-aws_sdk` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::AwsSdk', {
    inject_messaging_context: true,
    enable_internal_instrumentation: true
  }
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

### Configuration options

This instrumentation offers the following configuration options:

- `:inject_messaging_context` (default: `false`): When set to `true`, adds context key/value
  to Message Attributes for SQS/SNS messages.
- `:enable_internal_instrumentation` (default: `false`): When set to `true`, any spans with
  span kind of `internal` are traced.
- `:suppress_internal_instrumentation`: **Deprecated**. This configuration has been
  deprecated in favor of `:enable_internal_instrumentation`

## Integration with SDK V3's Telemetry support

AWS SDK for Ruby V3 added support for Observability which includes a new configuration,
`telemetry_provider` and an OpenTelemetry-based telemetry provider. Only applies to
AWS service gems released after 2024-09-03.

Using later versions of these gems will give more details on the internal spans.
See below for example usage:

```ruby
# configures the OpenTelemetry SDK with instrumentation defaults
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::AwsSdk'
end

# create open-telemetry provider and pass to client config
otel_provider = Aws::Telemetry::OTelProvider.new
client = Aws::S3::Client.new(telemetry_provider: otel_provider)
```

## SNS attributes

An `SNS.Publish` span carries `aws.sns.topic.arn` when the `TopicArn` request
parameter holds a topic ARN. `aws.sns.topic.arn` names an SNS topic
specifically, so it is read only from `TopicArn`. `TargetArn` names a platform
application or endpoint rather than a topic, so it never backs this attribute,
even when its value happens to be shaped like a topic ARN. `messaging.destination`
still names the selected destination, which is `TopicArn` when it holds a value
and `TargetArn` otherwise, so that behavior is unchanged.

The attribute holds the ARN unchanged, so it includes the AWS account ID and the
Region. Nothing needs to be configured: it is emitted by default whenever a
valid topic ARN is supplied through `TopicArn`. This registry attribute
currently has development stability.

A `TopicArn` value that is not a topic ARN is left out of `aws.sns.topic.arn`.
That covers subscription ARNs, foreign-service ARNs, malformed ARNs and phone
numbers. `TargetArn` destinations, such as platform application and endpoint
ARNs, are also left out of `aws.sns.topic.arn`. Those destinations are still
recorded, because `messaging.destination` keeps the last colon separated segment
of the selected value. For a platform endpoint or a subscription ARN that
segment is the endpoint or subscription identifier, which is per device or per
subscriber, so treat it as high-cardinality and potentially sensitive. That is
existing behavior and this attribute does not change it.

`messaging.destination_kind` stays `topic` on every `SNS.Publish` span, so it
reads `topic` even when the destination is a platform endpoint or a phone
number. That is also existing behavior and is left unchanged here.

## Example

To run the example:

1. `cd` to the examples directory and install gems
   - `cd example`
   - `bundle install`
2. Run the sample client script
   - `ruby trace_demonstration.rb`

This will run SNS publish command, printing OpenTelemetry traces to the console as it goes.

## How can I get involved?

The `opentelemetry-instrumentation-aws_sdk` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## Database semantic convention stability

In the OpenTelemetry ecosystem, database semantic conventions have now reached a stable state. However, the initial aws-sdk instrumentation was introduced before this stability was achieved, which resulted in database attributes being based on an older version of the semantic conventions.

To facilitate the migration to stable semantic conventions, you can use the `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable. This variable allows you to opt-in to the new stable conventions, ensuring compatibility and future-proofing your instrumentation.

When setting the value for `OTEL_SEMCONV_STABILITY_OPT_IN`, you can specify which conventions you wish to adopt:

- `database` - Emits the stable database and networking conventions and ceases emitting the old conventions previously emitted by the instrumentation.
- `database/dup` - Emits both the old and stable database and networking conventions, enabling a phased rollout of the stable semantic conventions.
- Default behavior (in the absence of either value) is to continue emitting the old database and networking conventions the instrumentation previously emitted.

For additional information on migration, please refer to our [documentation](https://opentelemetry.io/docs/specs/semconv/non-normative/db-migration/).

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[aws-sdk-home]: https://github.com/aws/aws-sdk-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
