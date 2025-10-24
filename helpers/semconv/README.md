# OpenTelemetry Semantic Convention Helpers

This gem provides semantic convention helpers for the OpenTelemetry framework, including HTTP span naming utilities. It is intended to be used by the instrumentation libraries and is not intended to be used directly by applications.

## Installation

Add a line similar to this in your `gemspec`:

```ruby
spec.add_dependency 'opentelemetry-helpers-semconv', '~> 0.1' # Use the appropriate version
```

Update your `Gemfile` to use the latest version of the gem in the contrib, if you are working locally in this repository e.g.

```ruby
group :test do
  gem 'opentelemetry-helpers-semconv', path: '../../helpers/semconv' # Use the appropriate path
end
```

## Usage

### HTTP Client Span Naming

The HTTP Client module provides consistent span naming for HTTP client operations using the `OpenTelemetry::Helpers::Semconv::HTTP::Client.name_from` method:

```ruby
require 'opentelemetry/helpers/semconv'

# Basic usage with HTTP method and URL template for client spans
attributes = {
  'http.request.method' => 'GET',
  'url.template' => '/users/:id'
}
span_name = OpenTelemetry::Helpers::Semconv::HTTP::Client.name_from(attributes)
# Returns: "GET /users/:id"

# Method normalization
attributes = { 'http.request.method' => 'post' }
span_name = OpenTelemetry::Helpers::Semconv::HTTP::Client.name_from(attributes)
# Returns: "POST"

# Fallback behavior
span_name = OpenTelemetry::Helpers::Semconv::HTTP::Client.name_from({})
# Returns: "HTTP"
```

### Integration with HTTP Client Instrumentation

Use in your HTTP client instrumentation libraries to create consistent spans:

```ruby
require 'opentelemetry/helpers/semconv'

# In your HTTP client instrumentation
def instrument_request(method, url, attributes = {})
  # Add HTTP attributes for span naming
  attributes['http.request.method'] = method
  attributes['url.template'] = extract_url_template(url) if url_template_available?

  span_name = OpenTelemetry::Helpers::Semconv::HTTP::Client.name_from(attributes)

  tracer.in_span(span_name, attributes: attributes) do |span|
    # perform HTTP request
    yield span if block_given?
  end
end
```

**Note**: This helper is specifically designed for HTTP **client** spans that use `url.template` attributes. For HTTP **server** spans, consider using `http.route` or other server-appropriate attributes for naming.

### Supported Attributes

The HTTP Client helper supports both current and legacy OpenTelemetry semantic conventions:

- **Current**: `http.request.method`, `url.template` (client spans only)
- **Legacy**: `http.method` (deprecated but supported for compatibility)
- **Behavior**: Prefers current conventions over legacy ones
- **Method normalization**: Automatically converts standard HTTP methods to uppercase (e.g., 'get' → 'GET')
- **Fallbacks**: Returns 'HTTP' when no recognizable attributes are present

**Important**: The `url.template` attribute is only applicable to HTTP client spans according to OpenTelemetry semantic conventions. Server spans should use `http.route` or other appropriate attributes.

### Supported HTTP Methods

The helper recognizes and normalizes the following standard HTTP methods:

- `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, `TRACE`
- Methods can be provided in any case (lowercase, uppercase, mixed) and will be normalized to uppercase
- Custom/non-standard methods are supported but may not be automatically normalized

## How can I get involved?

The `opentelemetry-helpers-semconv` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-helpers-semconv` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
