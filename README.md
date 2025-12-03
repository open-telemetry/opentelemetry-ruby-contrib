# OpenTelemetry Ruby Contrib

[![Slack channel][slack-image]][slack-url]
[![CI][ci-image]][ci-image]
[![Apache License][license-image]][license-image]

Contrib Packages for the [OpenTelemetry Ruby][otel-ruby] API and SDK implementation.

- [Getting Started][getting-started]
- [Contributing](#contributing)
- [Instrumentation Libraries](#instrumentation-libraries)
- [Versioning](#versioning)
- [Useful links](#useful-links)
- [License](#license)

## Contributing

We'd love your help! Use tags [good first issue][issues-good-first-issue] and
[help wanted][issues-help-wanted] to get started with the project.

Please review the [contribution instructions](CONTRIBUTING.md) for important
information on setting up your environment, running the tests, and opening pull
requests.

The Ruby special interest group (SIG) meets regularly. See the OpenTelemetry
[community page][ruby-sig] repo for information on this and other language SIGs.

### Maintainers

- [Andrew Hayworth](https://github.com/ahayworth)
- [Ariel Valentin](https://github.com/arielvalentin), GitHub
- [Daniel Azuma](https://github.com/dazuma), Google
- [Eric Mustin](https://github.com/ericmustin)
- [Francis Bogsanyi](https://github.com/fbogsany), Shopify
- [Kayla Reopelle](https://github.com/kaylareopelle), New Relic
- [Matthew Wear](https://github.com/mwear), Lightstep
- [Robb Kidd](https://github.com/robbkidd), Honeycomb
- [Robert Laurin](https://github.com/robertlaurin), Shopify
- [Sam Handler](https://github.com/plantfansam), Shopify

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

- [Josef Šimánek](https://github.com/simi)
- [Xuan Cao](https://github.com/xuan-cao-swi), Solarwinds

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).

## Instrumentation Libraries

This repository contains instrumentation libraries for many popular Ruby
gems, including Rails, Rack, Sinatra, and others, so you can start
using OpenTelemetry with minimal changes to your application. See the
[instrumentation README](instrumentation/) for more details.

## Helpers

This repository also contains libraries that hold code shared among
multiple instrumentation libraries.

- [MySQL](helpers/mysql/)
- [SQL Processor](helpers/sql-processor/)

## Additional Libraries

This repository also contains libraries to aid with interoperability with vendor specific tracing solutions:

- [Context Propagation](propagator/): OTTrace and Amazon X-Ray
- [Resource Detectors](resources/):
  - Azure
  - Container
  - Google Cloud Platform

## Versioning

OpenTelemetry Ruby follows the [versioning and stability document][otel-versioning] in the OpenTelemetry specification. Notably, we adhere to the outlined version numbering exception, which states that experimental signals may have a `0.x` version number.

### Ruby and Library Compatibility

All libraries in this repository require Ruby Versions 3.2 or newer.

- Ruby 3.1 EoL 2025-03-31 No longer receiving OTel Contrib updates as of 2025-09-30

This project is managed on a volunteer basis and therefore we have limited capacity to support compatibility with unmaintained or EOL libraries.

We will regularly review the instrumentations to drop compatibility for any versions of Ruby or gems that reach EOL or no longer receive regular maintenance.

Should you need instrumentation for _older_ versions of a library then you must pin to a specific version of the instrumentation that supports it,
however, you will no longer receive any updates for the instrumentation from this repository.

> When a release series is no longer supported, it's your own responsibility to deal with bugs and security issues. We may provide backports of the fixes and publish them to git, however there will be no new versions released. If you are not comfortable maintaining your own versions, you should upgrade to a supported version. <https://guides.rubyonrails.org/maintenance_policy.html#security-issues>

Consult instrumentation gem's README file and gemspec for details about library compatibility.

### Releases

This repository was extracted from the [OpenTelemetry Ruby repository][otel-ruby]. Versions of libraries contained in this repo released prior to 2022-06-13 are available on the [OpenTelemetry Ruby Releases][otel-ruby-releases] page. Newer versions are available [on the opentelemetry-ruby-contrib Releases page][otel-ruby-contrib-releases].

## Useful links

- For more information on OpenTelemetry, visit: <https://opentelemetry.io/>
- For help or feedback on this project, join us in [GitHub Discussions][discussions-url]

## License

Apache 2.0 - See [LICENSE][license-url] for more information.

[otel-ruby]: https://github.com/open-telemetry/opentelemetry-ruby
[otel-ruby-releases]: https://github.com/open-telemetry/opentelemetry-ruby/releases
[otel-ruby-contrib-releases]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/releases
[ci-image]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/workflows/CI%20Contrib/badge.svg?event=push
[getting-started]: https://opentelemetry.io/docs/languages/ruby/getting-started/
[issues-good-first-issue]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[issues-help-wanted]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22
[license-image]: https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat
[license-url]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[slack-image]: https://img.shields.io/badge/slack-@cncf/otel/ruby-brightgreen.svg?logo=slack
[slack-url]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[otel-versioning]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/versioning-and-stability.md
