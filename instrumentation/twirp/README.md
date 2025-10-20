# OpenTelemetry Twirp Instrumentation

The OpenTelemetry Twirp gem is a community maintained instrumentation for [Twirp][twirp-home], a simple RPC framework built on protobuf.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-twirp
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-twirp` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Twirp'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

### Configuration options

#### `:install_rack`

Default is `true`. Specifies whether to install Rack instrumentation as part of installing Twirp instrumentation. This is useful when you want to manually control where the Rack middleware is inserted.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Twirp', install_rack: false
end
```

#### `:peer_service`

Optionally set the `peer.service` attribute on client spans. This is useful for identifying the remote service being called.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Twirp', peer_service: 'backend-api'
end
```

## Examples

The `examples` directory contains:

- `server.rb` - A Twirp server with OpenTelemetry instrumentation
- `client.rb` - A Twirp client with OpenTelemetry instrumentation
- `greeter_service.rb` - Shared Twirp service definition

To run the example:

```bash
cd example
bundle install

# In one terminal, start the server:
ruby server.rb

# In another terminal, run the client:
ruby client.rb
```

You should see trace output in the console showing both client and server spans with RPC semantic attributes.

## Semantic Conventions

The Twirp instrumentation follows the [OpenTelemetry RPC semantic conventions](https://opentelemetry.io/docs/specs/semconv/rpc/rpc-spans/). The following attributes are set:

### Client Spans

- `rpc.system`: Always set to `"twirp"`
- `rpc.service`: The Twirp service name (e.g., `"example.Greeter"`)
- `rpc.method`: The RPC method name (e.g., `"Greet"`)
- `rpc.twirp.content_type`: The content type used (`"application/protobuf"` or `"application/json"`)
- `net.peer.name`: The server hostname
- `net.peer.port`: The server port
- `peer.service`: Optional, configured via the `peer_service` option
- `rpc.twirp.error_code`: Set when the RPC returns a Twirp error
- `rpc.twirp.error_msg`: Set when the RPC returns a Twirp error

### Server Spans

Server spans are created by the Rack instrumentation and enriched with:

- `rpc.system`: Always set to `"twirp"`
- `rpc.service`: The Twirp service name extracted from the request path
- `rpc.method`: The RPC method name extracted from the request path
- `rpc.twirp.content_type`: The content type from the request

The span name is also updated to `{service}/{method}` format.

## How can I get involved?

The `opentelemetry-instrumentation-twirp` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-twirp` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[twirp-home]: https://github.com/twitchtv/twirp-ruby
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/twirp/example
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/discussions
