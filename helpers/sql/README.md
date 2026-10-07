# OpenTelemetry Sql Helpers

This gem is intended to be used by the instrumentation libraries to provide a common set of helpers for SQL-related spans. It is not intended to be used directly by applications.

## Installation

Add a line similar to this in your `gemspec`:

```ruby

  spec.add_dependency 'opentelemetry-helpers-sql', '~> 0.3' # Use the approprite version

```

Update your `Gemfile` to use the latest version of the gem in the contrib, e.g.

```ruby

group :test do
  gem 'opentelemetry-helpers-sql', path: '../../helpers/sql' # Use the approprite path
end

```

## Usage

Some database libraries do not have enough context to add sufficient details to client spans. In these cases, you can use the `OpenTelemetry::Helpers::Sql.with_attributes` to create a set of shared attributes to amend to a database span.

```ruby
# Higher-level instrumentation e.g. ORM
OpenTelemetry::Helpers::Sql.with_attributes({ 'code.namespace' => 'Acme::Customer', 'code.function' => 'truncate!', 'db.operation.name' => 'TRUNCATE', 'db.namespace' => 'customers' }) do
  client.query('TRUNCATE customers')
end

# Client snippet
class OtherSqlClient
  def query(sql)
    tracer.in_span("query", attributes: OpenTelemetry::Helpers::Sql.attributes.merge('db.statement' => sql, 'db.system' => 'other_sql')) do
      connection.query(sql)
    end
  end
end
```

## How can I get involved?

The `opentelemetry-helpers-sql` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby Special Interest Group (SIG). You can find details on our weekly meeting times, GitHub Discussions, and CNCF Slack channels on the [Ruby SDK SIG page][ruby-sig].

## License

The `opentelemetry-helpers-sql` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community/blob/main/sigs.md#ruby-sdk
