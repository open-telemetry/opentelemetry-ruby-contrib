# OpenTelemetry Trilogy Instrumentation

The OpenTelemetry Trilogy Ruby gem provides instrumentation for [Trilogy][trilogy-home] and
was `COPY+PASTE+MODIFIED` from the [`OpenTelemetry MySQL`][opentelemetry-mysql].

Some key differences in this instrumentation are:

- `Trilogy` does not expose [`MySql#query_options`](https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L78), therefore there is limited support for database semantic conventions.
- SQL Obfuscation is enabled by default to mitigate restricted data leaks.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-trilogy
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-trilogy` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Trilogy', {
    # The obfuscation of SQL in the db.statement attribute is disabled by default.
    # To enable, set db_statement to :obfuscate.
    db_statement: :obfuscate,
  }
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

The `trilogy` instrumentation allows the user to supply additional attributes via the `with_attributes` method. This makes it possible to supply additional attributes on trilogy spans. Attributes supplied in `with_attributes` supersede those automatically generated within `trilogy`'s automatic instrumentation. If you supply a `db.statement` attribute in `with_attributes`, this library's `:db_statement` configuration will not be applied.

```ruby
require 'opentelemetry-instrumentation-trilogy'

client = Trilogy.new(:host => 'localhost', :username => 'root')
OpenTelemetry::Instrumentation::Trilogy.with_attributes('pizzatoppings' => 'mushrooms') do
  client.query('SELECT 1')
end
```

## Configuration Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `db_statement` | `:obfuscate` | Controls how SQL queries appear in spans. `:obfuscate` replaces literal values with `?`, `:include` records the raw SQL, `:omit` excludes the attribute entirely. |
| `obfuscation_limit` | `2000` | Maximum length of the obfuscated SQL statement. Statements exceeding this limit are truncated. |
| `peer_service` | `nil` | Sets the `peer.service` attribute on spans (old semantic conventions only). |
| `propagator` | `'none'` | Propagator for injecting trace context into SQL comments. `'none'` disables propagation, `'tracecontext'` uses W3C Trace Context, `'vitess'` uses Vitess-style propagation (requires `opentelemetry-propagator-vitess` gem). |
| `record_exception` | `true` | Records exceptions as span events when an error occurs. |
| `span_name` | `:statement_type` | Controls span naming (old semantic conventions only). `:statement_type` uses the SQL operation (e.g., `SELECT`), `:db_name` uses the database name, `:db_operation_and_name` combines both. |

## Semantic Conventions

This instrumentation generally uses [Database semantic conventions](https://opentelemetry.io/docs/specs/semconv/database/database-spans/). See the [Database semantic convention stability](#database-semantic-convention-stability) section for how to switch between stable and old conventions.

| Stable Attribute Name | Old Attribute Name | Type | Notes |
| - | - | - | - |
| `db.namespace` | `db.name` | String | Database name from connection_options |
| `db.query.text` | `db.statement` | String | The database query being executed; set according to the `db_statement` config option |
| `db.response.status_code` | — | String | The Trilogy error code, if available |
| `db.system.name` | `db.system` | String | DBMS product identifier; always `mysql` |
| `error.type` | — | String | The exception class name when the operation fails |
| `server.address` | `net.peer.name` | String | Database host from connection_options |
| `server.port` | — | Integer | Database port from connection_options |
| — | `db.instance.id` | String | Connected host, e.g. result of `SELECT @@hostname` |
| — | `db.user` | String | Database username from connection_options |
| — | `peer.service` | String | Configured via the `peer_service` config option |

## Database semantic convention stability

In the OpenTelemetry ecosystem, database semantic conventions have now reached a stable state. However, the initial Trilogy instrumentation was introduced before this stability was achieved, which resulted in database attributes being based on an older version of the semantic conventions.

To facilitate the migration to stable semantic conventions, you can use the `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable. This variable allows you to opt-in to the new stable conventions, ensuring compatibility and future-proofing your instrumentation.

When setting the value for `OTEL_SEMCONV_STABILITY_OPT_IN`, you can specify which conventions you wish to adopt:

- `database` - Emits the stable database and networking conventions and ceases emitting the old conventions previously emitted by the instrumentation.
- `database/dup` - Emits both the old and stable database and networking conventions, enabling a phased rollout of the stable semantic conventions.
- Default behavior (in the absence of either value) is to continue emitting the old database and networking conventions the instrumentation previously emitted.

During the transition from old to stable conventions, Trilogy instrumentation code comes in three patch versions: `dup`, `old`, and `stable`. These versions are identical except for the attributes they send. Any changes to Trilogy instrumentation should consider all three patches.

For additional information on migration, please refer to our [documentation](https://opentelemetry.io/docs/specs/semconv/non-normative/db-migration/).

## How can I get involved?

The `opentelemetry-instrumentation-trilogy` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-trilogy` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[trilogy-home]: https://github.com/github/trilogy
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[opentelemetry-mysql]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/mysql2
