# Sinatra Instrumentation

The Sinatra instrumentation is a community-maintained instrumentation for the [Sinatra][sinatra-home] Web Framework.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-sinatra
```


Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-sinatra` to your `Gemfile`.

### Version Compatibility

Older versions of Sinatra depend on older version of Rack, which are not supported by the latest version of Rack instrumentation. If you are using an older version of Sinatra and need an earlier version of Rack instrumentation, then consider installing and pinning the compatible gem version, e.g.:

```console
gem opentelemetry-instrumentation-rack, "<version>"
```

| Sinatra Version | Rack Instrumentation Version |
| --------------- | ---------------------------- |
| `< 2.0`         | `= 0.22.1`                   |
| `>= 2.0`        | `~> 0.22`                    |

## Usage

To install the instrumentation, add the gem to your Gemfile:

```ruby
gem 'opentelemetry-instrumentation-sinatra'
```

Then call `use` with the name of the instrumentation:

```ruby
require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## How can I get involved?

The `opentelemetry-instrumentation-sinatra` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-sinatra` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[sinatra-home]: http://sinatrarb.com
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
