# OpenTelemetry Mysql2 Instrumentation

The OpenTelemetry Mysql2 Ruby gem is a community maintained instrumentation for [Mysql2][mysql2-home].

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-mysql2
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-mysql2` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mysql2'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

The `mysql2` instrumentation allows the user to supply additional attributes via the `with_attributes` method. This makes it possible to supply additional attributes on mysql2 spans. Attributes supplied in `with_attributes` supersede those automatically generated within `mysql2`'s automatic instrumentation. If you supply a `db.statement` attribute in `with_attributes`, this library's `:db_statement` configuration will not be applied.

```ruby
require 'opentelemetry/instrumentation/mysql2'

client = Mysql2::Client.new(:host => "localhost", :username => "root")
OpenTelemetry::Instrumentation::Mysql2.with_attributes('pizzatoppings' => 'mushrooms') do
  client.query("SELECT 1")
end
```

### Configuration options

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mysql2', {
    # The obfuscation of SQL in the db.statement attribute is enabled by default.
    # To disable, set db_statement to :include; to omit the query completely, set db_statement to :omit
    db_statement: :include,

    # When db_statement is :obfuscate, queries up to 2000 characters are obfuscated by default.
    # Longer queries are not obfuscated: the attribute holds a message saying the query
    # exceeded the limit. Higher values may impact performance.
    obfuscation_limit: 2000,

    # By default, trace context is not added to queries. Set this option to 'tracecontext'
    # to append the W3C trace context to each query as a SQL comment, or to 'vitess' for
    # Vitess-style propagation (requires the opentelemetry-propagator-vitess gem).
    propagator: 'tracecontext',

    # Spans are named after the SQL operation (for example `select`) by default.
    # Set :db_name to use the database name, or :db_operation_and_name to combine both.
    # Spans fall back to `mysql` when no name can be derived.
    span_name: :db_operation_and_name,
  }
end
```

## Examples

An example of usage can be seen in [`example/mysql2.rb`](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/mysql2/example/mysql2.rb).

## How can I get involved?

The `opentelemetry-instrumentation-mysql2` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-instrumentation-mysql2` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[mysql2-home]: https://github.com/brianmario/mysql2
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
