# OpenTelemetry OpenAI Instrumentation

The OpenAI instrumentation is a community-maintained instrumentation for the [OpenAI][openai-home] gem.

Attributes and events follow the [OpenTelemetry Semantic Conventions for Generative AI][semconv-genai], pinned to core semantic conventions version `1.44.0`.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-openai
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-openai` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::OpenAI'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Configuration options

The instrumentation accepts the following configuration options:

| Option | Default | Description |
| --- | --- | --- |
| `:capture_content` | `false` | Captures the content of prompts and responses (chat messages, inputs, prompts, and tool call arguments) as structured `gen_ai` log records emitted through the OpenTelemetry Logs API. Disabled by default to avoid recording potentially sensitive data. This option is overridden at install time by the `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` environment variable. |
| `:allowed_operations` | `["chat", "completions", "embeddings"]` | The list of OpenAI operations to instrument. Only requests whose resolved operation name is included here produce spans; all other operations pass through untouched. |

Options are passed to `use` in the SDK configuration:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::OpenAI', {
    capture_content: true,
    allowed_operations: %w[chat completions embeddings]
  }
end
```

Content capture can also be enabled without changing code by setting the
environment variable:

```console
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true
```

## Emitting log events

[GenAI semantic conventions define events to emit with instrumentation][genai-semconv-events]. Events are emitted using the Logs signal. The `opentelemetry-instrumentation-openai` gem does not depend on the `opentelemetry-logs-api` gem because it has not reached stability. However, if you have the Logs API and Logs SDK gems installed in your Gemfile, it will emit Log Records for the GenAI events.

To enable the instrumentation to emit logs, add the following to your Gemfile:

```ruby
gem 'opentelemetry-logs-api'
gem 'opentelemetry-logs-sdk'
```

## Examples

See [example/trace_demonstration.rb][example-github] for a runnable example that instruments chat completion, streaming, and embeddings requests and prints spans and log records to the console. Set the `OPENAI_API_KEY` environment variable before running it.

```sh
OPENAI_API_KEY=<openai_api_key> ruby trace_demonstration.rb
```

## How can I get involved?

The `opentelemetry-instrumentation-openai` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-openai` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[openai-home]: https://github.com/openai/openai-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[semconv-genai]: https://github.com/open-telemetry/semantic-conventions-genai
[example-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/openai/example/trace_demonstration.rb
[genai-semconv-events]: https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/gen-ai-events.md
