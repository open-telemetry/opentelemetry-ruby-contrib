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

## How can I get involved?

The `opentelemetry-instrumentation-mysql2` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-mysql2` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[mysql2-home]: https://github.com/brianmario/mysql2
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions

## Database semantic convention stability

In the OpenTelemetry ecosystem, database semantic conventions have now reached a stable state. However, the initial Mysql2 instrumentation was introduced before this stability was achieved, which resulted in database attributes being based on an older version of the semantic conventions.

To facilitate the migration to stable semantic conventions, you can use the `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable. This variable allows you to opt-in to the new stable conventions, ensuring compatibility and future-proofing your instrumentation.

When setting the value for `OTEL_SEMCONV_STABILITY_OPT_IN`, you can specify which conventions you wish to adopt:

- `database` - Emits the stable database and networking conventions and ceases emitting the old conventions previously emitted by the instrumentation.
- `database/dup` - Emits both the old and stable database and networking conventions, enabling a phased rollout of the stable semantic conventions.
- Default behavior (in the absence of either value) is to continue emitting the old database and networking conventions the instrumentation previously emitted.

During the transition from old to stable conventions, Mysql2 instrumentation code comes in three patch versions: `dup`, `old`, and `stable`. These versions are identical except for the attributes they send. Any changes to Mysql2 instrumentation should consider all three patches.

For additional information on migration, please refer to our [documentation](https://opentelemetry.io/docs/specs/semconv/non-normative/db-migration/).
