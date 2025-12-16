# OpenTelemetry ActionView Instrumentation

The OpenTelemetry ActionView gem is a community maintained instrumentation for the ActionView portion of the [Ruby on Rails][rails-home] web-application framework.

## How do I get started?

Install the gem using:

```console
gem install opentelemetry-instrumentation-action_view
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-action_view` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActionView'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Active Support Instrumentation

This instrumentation relies on `ActiveSupport::Notifications` and registers subscriptions to listen to relevant events and report them as spans.

See the table below for details of what [Rails Framework Hook Events](https://guides.rubyonrails.org/active_support_instrumentation.html#action-view) are recorded by this instrumentation:

| Event Name | Creates Span? | Notes |
| - | - | - |
| `render_template.action_view` | :white_check_mark: | Captures template rendering operations |
| `render_partial.action_view` | :white_check_mark: | Captures partial template rendering operations |
| `render_collection.action_view` | :white_check_mark: | Captures collection rendering operations |
| `render_layout.action_view` | :white_check_mark: | Captures layout rendering operations |

## Semantic Conventions

This instrumentation follows OpenTelemetry semantic conventions for view rendering. The Rails ActiveSupport notification payload keys are automatically transformed to semantic convention attribute names:

| Rails Notification Key | Semantic Convention Attribute | Description |
|------------------------|-------------------------------|-------------|
| `identifier` | `code.filepath` | The template file path being rendered |
| `layout` | `view.layout.code.filepath` | The layout template file path (if applicable) |
| `count` | `view.collection.count` | The number of items in a collection render |

### Attributes

Attributes that are specific to this instrumentation are recorded for each event:

| Attribute Name              | Type    | Notes                                                                                                                                  |
| --------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `code.filepath`             | String  | Template or partial file path (e.g., `"posts/index"`, `"posts/_form"`)                                                                |
| `view.layout.code.filepath` | String  | Layout file path (e.g., `"application"`) - only present for `render_template.action_view` events when a layout is used                |
| `view.collection.count`     | Integer | Number of items rendered - only present for `render_collection.action_view` events                                                    |

**Note:** The `locals` hash parameter is not recorded as an attribute because OpenTelemetry specification v1.10.0 only supports primitive types (string, boolean, numeric, and arrays of primitives) as span attributes, and the locals hash contains complex Ruby objects.

## Examples

Example usage can be seen in the [`./example/trace_request_demonstration.ru` file](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/action_view/example/trace_request_demonstration.ru)

## Known issues

ActionView instrumentation uses ActiveSupport notifications and in the case when a subscriber raises in start method an unclosed span would break successive spans ends. Example:

```ruby
class CrashingEndSubscriber
  def start(name, id, payload)
    raise 'boom'
  end

  def finish(name, id, payload) end
end

::ActiveSupport::Notifications.subscribe('render_template.action_view', CrashingStartSubscriber.new)
```

## How can I get involved?

The `opentelemetry-instrumentation-action_view` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-action_view` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[rails-home]: https://github.com/rails/rails
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
