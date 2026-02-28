# OpenTelemetry ActiveRecord Instrumentation

The Active Record instrumentation is a community-maintained instrumentation for the Active Record portion of the [Ruby on Rails][rails-home] web-application framework.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-active_record
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-active_record` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Configuration Options

The instrumentation supports the following configuration options:

- **enable_notifications_instrumentation:** Enables instrumentation of SQL queries using ActiveSupport notifications. When enabled, generates spans for each SQL query with additional metadata including operation names, async status, and caching information.
  - Default: `false`

## Active Support Instrumentation

This instrumentation can optionally leverage `ActiveSupport::Notifications` to provide detailed SQL query instrumentation. When enabled via the `enable_notifications_instrumentation` configuration option, it subscribes to `sql.active_record` events to create spans for individual SQL queries.

### Enabling SQL Notifications

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord',
        enable_notifications_instrumentation: true
end
```

See the table below for details of what [Rails ActiveRecord Events](https://guides.rubyonrails.org/active_support_instrumentation.html#active-record) are recorded by this instrumentation:

| Event Name | Creates Span? | Notes |
| - | - | - |
| `sql.active_record` | :white_check_mark: | Creates an `internal` span for each SQL query with operation name, async status, and caching information |

### SQL Query Spans

When notifications instrumentation is enabled, each SQL query executed through ActiveRecord generates a span with:

- **Span name**: Derived from the query operation (e.g., `"User Create"`, `"Account Load"`, `"Post Update"`)
- **Span kind**: `internal`
- **Attributes**:
  - `rails.active_record.query.async` (boolean): Present and set to `true` for asynchronous queries
  - `rails.active_record.query.cached` (boolean): Present and set to `true` for cached query results

## Examples

Example usage can be seen in the [`./example/trace_demonstration.rb` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/active_record/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-active_record` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-active_record` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[rails-home]: https://rubyonrails.org/
