# OpenTelemetry Sql Helpers

Todo: Add a description.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-helpers-sql
```

Or, if you use [bundler][bundler-home], include `opentelemetry-helpers-sql` in your `Gemfile`.

## Usage

This gem is intended to be used by the instrumentation libraries to provide a common set of helpers for SQL-related spans. It is not intended to be used directly by applications.

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

The `opentelemetry-helpers-sql` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-helpers-sql` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
