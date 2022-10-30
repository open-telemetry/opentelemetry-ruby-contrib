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

### Configuration options

| Name  | Default | Description |
| ----- | ------- | ----------- |
| `span_naming`  | `:rails_route`  | Configures the name for the Rack span. `:rails_route` is in the format of `HTTP_METHOD /rails/route(.:format)`, for example `GET /users/:id(.:format)`. `:controller_action` is in the format of `Controller#action`, for example `UsersController#show` |
| `enable_recognize_route`  | `true`  | Enables or disables adding the `http.route` attribute. |

The default configuration uses a [method from Rails to obtain the route for the request](https://github.com/rails/rails/blob/v6.1.3/actionpack/lib/action_dispatch/journey/router.rb#L65). The options above allow this behaviour to be opted out of if you have performance issues. If you wish to avoid using this method then set `span_naming: :controller_action, enable_recognize_route: false`.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActionPack', {
    span_naming: :controller_action,
    enable_recognize_route: false
  }
end
```

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
