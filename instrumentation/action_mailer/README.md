# OpenTelemetry ActionMailer Instrumentation

The ActionMailer instrumentation is a community-maintained instrumentation for the ActionMailer portion of the [Ruby on Rails][rails-home] web-application framework.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-action_mailer
gem install opentelemetry-instrumentation-rails
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-action_mailer` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::ActionMailer'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```


## Active Support Instrumentation

This instrumentation now relies entirely on `ActiveSupport::Notifications` and registers a custom Subscriber that listens to relevant events to report as spans.

See the table below for details of what [Rails Framework Hook Events](https://guides.rubyonrails.org/active_support_instrumentation.html#action-mailer) are recorded by this instrumentation:

| Event Name | Creates Span? | Notes |
| - | - | - |
| `deliver.action_mailer` | :white_check_mark: | Creates an span with kind `internal` and email content and status|
| `process.action_mailer` | :x: | Lack of useful info so ignored |

## Semantic Conventions

Internal spans are named using the name of the `ActiveSupport` event that was provided (e.g. `action_mailer deliver`).

Attributes that are specific to this instrumentation are recorded under `action_mailer deliver`:

| Attribute Name | Type | Notes |
| - | - | - |
| `mail` | String | Mail content |
| `mailer` | String | Mailer class that is used to send mail |
| `message_id` | String | Set from Mail gem|
| `subject` | String | Mail subject |
| `to` | Array | Receiver for mails (omit when `email_address` set to `:omit` |
| `from` | Array | Sender for mails (omit when `email_address` set to `:omit` |
| `cc` | Array | mails CC (omit when `email_address` set to `:omit` |
| `bcc` | Array | mails BCC (omit when `email_address` set to `:omit` |
| `perform_deliveries` | Boolean | mail status |

## Examples

Example usage can be seen in the `./example/trace_request_demonstration.ru` file [here](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/action_mailer/example/trace_request_demonstration.ru)


## How can I get involved?

The `opentelemetry-instrumentation-action_mailer` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-action_mailer` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[rails-home]: https://github.com/rails/rails
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
