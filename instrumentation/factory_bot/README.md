# OpenTelemetry FactoryBot Instrumentation

The FactoryBot instrumentation is a community-maintained instrumentation for the [FactoryBot](https://github.com/thoughtbot/factory_bot) gem.

This instrumentation creates spans for FactoryBot operations (create, build, build_stubbed, attributes_for), providing visibility into test data creation patterns. This is particularly useful when combined with ActiveRecord instrumentation, as it makes it explicit which database operations are triggered by FactoryBot vs direct ActiveRecord calls.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-factory_bot
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-factory_bot` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::FactoryBot'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the [example/](example/) directory

A simple example:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/factory_bot'
require 'factory_bot'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::FactoryBot'
end

# Define a factory
FactoryBot.define do
  factory :user do
    name { 'Test User' }
    email { 'test@example.com' }
  end
end

# Create a user - this will generate a span named "FactoryBot.build(user)"
user = FactoryBot.build(:user)
```

## Span Attributes

The instrumentation adds the following attributes to spans:

- `factory_bot.strategy` - The internal strategy name (create, build, stub, attributes_for)
- `factory_bot.factory_name` - The name of the factory being used
- `factory_bot.traits` - Comma-separated list of traits applied (if any)

## How can I get involved?

The `opentelemetry-instrumentation-factory_bot` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-factory_bot` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
