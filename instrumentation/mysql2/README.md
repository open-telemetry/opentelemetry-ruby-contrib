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
  }
end
```

## Examples

An example of usage can be seen in [`example/mysql2.rb`](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/mysql2/example/mysql2.rb).

## Known issues running the test suite

Currently Alpine Linux's MariaDB Connector/C 3.4.x requires SSL unconditionally, which causes the test suite to fail.

Because of this the Dev Container/Docker harness has been moved to a minimal Ubuntu image.

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
