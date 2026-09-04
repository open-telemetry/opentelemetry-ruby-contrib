# OpenTelemetry LMDB Instrumentation

The LMDB instrumentation is a community-maintained instrumentation for the [LMDB][lmdb-home] gem.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-lmdb
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-lmdb` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::LMDB'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Configuration

Options are passed as a hash to `use`:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::LMDB', { db_statement: :include }
end
```

| Option | Default | Values |
| --- | --- | --- |
| `db_statement` | `:obfuscate` | `:obfuscate`, `:include`, `:omit` |
| `peer_service` | `nil` | any string |

### `db_statement`

Controls whether the key and value appear in the recorded statement:

- `:obfuscate` (default) — replaces the key and any value with `?`, so no user data reaches the span. For example `PUT ? ?`, `GET ?`, `DELETE ? ?`.
- `:include` — records the key and value, for example `PUT mykey myvalue`, truncated to 500 characters.
- `:omit` — the attribute is not emitted at all.

The attribute written is `db.query.text` under the stable conventions and `db.statement` under the old conventions. See [`database/dup` caveats](#databasedup-caveats) for how this behaves when both are emitted.

### `peer_service`

Sets the `peer.service` attribute. The stable conventions do not include `peer.service`, so this option has no effect when `OTEL_SEMCONV_STABILITY_OPT_IN` is set to `database`.

## How can I get involved?

The `opentelemetry-instrumentation-lmdb` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## Database semantic convention stability

In the OpenTelemetry ecosystem, database semantic conventions have now reached a stable state. However, the initial LMDB instrumentation was introduced before this stability was achieved, which resulted in database attributes being based on an older version of the semantic conventions.

To facilitate the migration to stable semantic conventions, you can use the `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable. This variable allows you to opt-in to the new stable conventions, ensuring compatibility and future-proofing your instrumentation.

When setting the value for `OTEL_SEMCONV_STABILITY_OPT_IN`, you can specify which conventions you wish to adopt:

- `database` - Emits the stable database and networking conventions and ceases emitting the old conventions previously emitted by the instrumentation.
- `database/dup` - Emits both the old and stable database and networking conventions, enabling a phased rollout of the stable semantic conventions.
- Default behavior (in the absence of either value) is to continue emitting the old database and networking conventions the instrumentation previously emitted.

During the transition from old to stable conventions, LMDB instrumentation code comes in three patch versions: `dup`, `old`, and `stable`. These versions differ in the attributes they send, and the `stable` patch also differs in span kind and span name. Any changes to LMDB instrumentation should consider all three patches.

### `database/dup` caveats

`database/dup` emits both sets of attributes on a single span, so old- and stable-convention consumers can both be served during a phased rollout. Two things cannot be duplicated, because a span has exactly one of each. In both cases `dup` keeps the old behavior, so consumers reading the old conventions are not broken mid-migration:

- **Span kind.** Under `database`, database operations are `INTERNAL`, because LMDB is an embedded store mapped into the current process with no remote server. Under `database/dup` and under the default they remain `CLIENT`.
- **Span name.** Under `database`, span names are `GET`, `PUT`, `DELETE`, and `CLEAR`. Under `database/dup` and under the default they also carry the key, for example `GET mykey`.

In addition, **`db.statement` is never obfuscated.** The old conventions did not sanitize it, so under `database/dup` it carries the key and value verbatim whenever `db_statement` is not `:omit` — including under the `:obfuscate` default. Only `db.query.text` is obfuscated.

The practical consequence is that `db_statement: :obfuscate` does not by itself keep keys and values from being exported until you move from `database/dup` to `database`, since both `db.statement` and the span name still carry them. If you need that guarantee during a phased rollout, use `db_statement: :omit`.

For additional information on migration, please refer to our [documentation](https://opentelemetry.io/docs/specs/semconv/non-normative/db-migration/).

## License

The `opentelemetry-instrumentation-lmdb` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[lmdb-home]: https://github.com/minad/lmdb
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
