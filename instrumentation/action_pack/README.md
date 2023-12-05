# OpenTelemetry ActionPack Instrumentation

The Action Pack instrumentation is a community-maintained instrumentation for the Action Pack portion of the [Ruby on Rails][rails-home] web-application framework.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-action_pack
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-action_pack` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActionPack'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Active Support Instrumentation

Earlier versions of this instrumentation relied on patching custom `dispatch` hooks from Rails's [Action Controller](https://github.com/rails/rails/blob/main/actionpack/lib/action_controller/metal.rb#L224) to extract request information.

This instrumentation now relies on `ActiveSupport::Notifications` and registers a custom Subscriber that listens to relevant events to modify the Rack span.

See the table below for details of what [Rails Framework Hook Events](https://guides.rubyonrails.org/active_support_instrumentation.html#action-controller) are recorded by this instrumentation:

| Event Name | Subscribe? | Creates Span? |  Notes |
| - | - | - | - |
| `process_action.action_controller` | :white_check_mark: | :x: | It modifies the existing Rack span |


### Error Handling for Action Controller

If an error is triggered by Action Controller (such as a 500 internal server error), Action Pack will typically employ the default `ActionDispatch::PublicExceptions.new(Rails.public_path)` as the `exceptions_app`, as detailed in the [documentation](https://guides.rubyonrails.org/configuring.html#config-exceptions-app).

The error object will be retained within `payload[:exception_object]`. Additionally, its storage in `request.env['action_dispatch.exception']` is contingent upon the configuration of `action_dispatch.show_exceptions` in Rails.

## Examples

Example usage can be seen in the `./example/trace_demonstration.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/instrumentation/action_pack/example/trace_demonstration.ru)

## How can I get involved?

The `opentelemetry-instrumentation-action_pack` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-action_pack` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
