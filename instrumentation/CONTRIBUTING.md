# Instrumentation author's guide

This guide is for authors of OpenTelemetry Ruby instrumentation libraries. It provides guidance on how to contribute an instrumentation library.

Please make sure to read and understand the [CONTRIBUTING](../CONTRIBUTING.md) guide before submitting any changes to instrumentation.

## What we expect from you

We are a community of volunteers with a shared goal of improving observability in Ruby applications.

We welcome contributions from everyone. We want to make sure that you have a great experience contributing to this project, as well as a positive impact on the Ruby community.

We have limited capacity to maintain instrumentation libraries, so we ask that you commit to maintaining the instrumentation library you contribute.

In addition to the requirements to maintain at least [community member status](https://github.com/open-telemetry/community/blob/main/community-membership.md), contributing an instrumentation to this project requires the following:

1. Responding to issues and pull requests
2. Performing timely code reviews and responding to issues
3. Addressing security vulnerabilities
4. Keeping the instrumentation library up to date with the latest:
    * OpenTelemetry Ruby API and SDK changes
    * Ruby language changes
    * Instrumented library changes

If you do not have the capacity to maintain the instrumentation library, please consider contributing to the OpenTelemetry Ruby project in other ways or consider creating a separate project for the instrumentation library.

> :warning: Libraries that do not meet these requirements may be removed from the project at any time at the discretion of OpenTelemetry Ruby Contrib Maintainers.

## Contributing a new instrumentation library

Our long-term goal is to provide instrumentation for all popular Ruby libraries. Ideally, we would like to have first-party instrumentation for all libraries maintained by the gem's authors to ensure compatibility with upstream gems. However, in many cases this is not possible.

For this reason, we welcome contributions of new instrumentation libraries that cannot be maintained by the original gem authors as first-party instrumentation.

The following steps are required to contribute a new instrumentation library:

1. Generate an instrumentation gem skeleton
2. Implement the instrumentation library, including comprehensive automated tests
3. Add the instrumentation library to the appropriate CI workflows
4. Include documentation for your instrumentation
    * Document all instrumentation-specific configuration options in the `README.md` and `yardoc` class comments
    * Document all semantic conventions used by the instrumentation in the `README.md`
    * Provide executable examples in an `examples` directory
5. Submit a pull request

## Generate the gem

This repository contains a script to generate a new instrumentation library.

The snippet below demonstrates how to generate a an instrumentation for the `werewolf` gem, starting from the repository root.

```console

$bash opentelemetry-ruby-contrib> bin/instrumentation_generator werewolf

```

The output of the generator shows that it creates a new directory in the `instrumentation` directory using the name of the gem:

``` console

🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

 WARNING: Your gem will *NOT* be tested until you add it to the CI workflows in `.github/workflows/ci.yml`!!

🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

      create  instrumentation/werewolf/.rubocop.yml
      create  instrumentation/werewolf/.yardopts
      create  instrumentation/werewolf/Appraisals
      create  instrumentation/werewolf/CHANGELOG.md
      create  instrumentation/werewolf/Gemfile
      create  instrumentation/werewolf/LICENSE
      create  instrumentation/werewolf/opentelemetry-instrumentation-werewolf.gemspec
      create  instrumentation/werewolf/Rakefile
      create  instrumentation/werewolf/README.md
      create  instrumentation/werewolf/lib/opentelemetry-instrumentation-werewolf.rb
      create  instrumentation/werewolf/lib/opentelemetry/instrumentation.rb
      create  instrumentation/werewolf/lib/opentelemetry/instrumentation/werewolf.rb
      create  instrumentation/werewolf/lib/opentelemetry/instrumentation/werewolf/instrumentation.rb
      create  instrumentation/werewolf/lib/opentelemetry/instrumentation/werewolf/version.rb
      create  instrumentation/werewolf/test/test_helper.rb
      create  instrumentation/werewolf/test/opentelemetry/instrumentation/werewolf/instrumentation_test.rb
      insert  .toys/.data/releases.yml
      insert  instrumentation/all/Gemfile
      insert  instrumentation/all/opentelemetry-instrumentation-all.gemspec
      insert  instrumentation/all/lib/opentelemetry/instrumentation/all.rb

```

## Implementation guidelines

The original design and implementation of this project was heavily influenced by Datadog's `dd-trace-rb` project. You may refer to the [Datadog Porting Guide](datadog-porting-guide.md) as a reference for implementing instrumentations, however, the following guidelines are specific to OpenTelemetry Ruby:

* Use `OpenTelemetry::Instrumentation::Base`
* Use the OpenTelemetry API
* Use first-party extension points
* Use Semantic Conventions
* Write comprehensive automated tests
* Understand performance characteristics

### Use `OpenTelemetry::Instrumentation::Base`

The entry point of your instrumentation should be implemented as a subclass of `OpenTelemetry::Instrumentation::Base`:

* Implement an `install` block, where all of the integration work happens
* Implement a `present` block, which checks whether the library you are instrumenting was loaded
* Implement a `compatible` block and check for at least the minimum required library version
  * OpenTelemetry Ruby Contrib generally supports only versions of gems that are within the maintenance window
* Add any custom configuration `options` you want to support

The example below demonstrates how to implement the `Werewolf` instrumentation:

```ruby

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Werewolf
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('0.1.0')

        install do |_config|
          require_relative 'handlers'
          Handlers.subscribe
        end

        option :transformations, default: :omit, validate: %i[omit include]

        present do
          defined?(::Werewolf) && defined?(::ActiveSupport)
        end

        compatible do
          Gem::Version.new(::Wereworlf::VERSION) >= MINIMUM_VERSION
        end
      end
    end
  end
end

```

* The `install` block lazily requires the instrumentation handlers, which subscribe to events published by the `Werewolf` event hooks.
* The `present` block checks if the `Werewolf` and `ActiveSupport` libraries are loaded, which it will use to subscribe to events and generate spans. It will skip the installation if those dependencies were not loaded before the instrumentation was initialized.
* The `compatible` block checks if the `Werewolf` library version is at least `0.1.0` and will skip installation if it is not.
* The `options` section allows you to define custom configuration options that can be passed to the instrumentation. In this example, the `transformations` option is defined with a default value of `:omit` and a validation rule that only allows `:omit` or `:include` values.

### Use the OpenTelemetry API

Instrumentations are intended to be portable and usable with vendor distributions of the SDK. For this reason, you must use the [OpenTelemetry API](https://github.com/open-telemetry/opentelemetry-ruby/tree/main/api) to create spans and add attributes, events, and links to spans and avoid using the [OpenTelemetry SDK](https://github.com/open-telemetry/opentelemetry-ruby/tree/main/sdk) directly.

Each instrumentation _must_ use a named tracer. Instrumentations that inherit from `OpenTelemetry::Instrumentation::Base` will get a single helper method that will automatically provide your instrumentation with a named tracer under `OpenTelemetry::Instrumentation::${Gem Name}::Instrumentation.instance.tracer`.

For example, the `Werewolf` module generated in the example above is available via `OpenTelemetry::Instrumentation::Werewolf::Instrumentation.instance.tracer`. You should reference this tracer in your code when creating spans like this:

```ruby

  OpenTelemetry::Instrumentation::Werewolf::Instrumentation.instance.tracer.start_span('transform') do
    # code to be traced
  end

```

> :warning: This tracer is not _upgradable_ before the SDK is initialized, therefore it is important that your instrumentation _always_ use stack local references of the tracer.

### Use first-party extension points

Whenever possible, use first-party extension points (hooks) to instrument libraries. This ensures that the instrumentation is compatible with the latest versions of the library and that the instrumentation is maintained by the library authors. [`ActiveSupport::Notifications`](https://guides.rubyonrails.org/active_support_instrumentation.html) and `Middleware` are good examples of first-party extension points used by our instrumentation libraries.

Monkey patching is discouraged in OpenTelemetry Ruby because it is the most common source of bugs and incompatability with the libraries we instrument. If you must monkey patch, please ensure that the monkey patch is as isolated as possible and that it is clearly documented.

### Use Semantic Conventions

Use the [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/concepts/semantic-conventions/) to ensure the instrumentation is compatible with other OpenTelemetry libraries and that the data is useful in a distributed context.

> :information_source: Privacy and security are important considerations when adding attributes to spans. Please ensure that you are not adding sensitive information to spans. If you are unsure, please ask for a review.

When semantic conventions do not exist, use the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html) and submit an Issue/PR with your attributes to the [Semantic Conventions repo](https://github.com/open-telemetry/semantic-conventions) to propose a new set of standard attributes.

If the attribute is specific to your instrumentation, then consider namespacing it using the `instrumentation` prefix e.g. `werewolf.bite.damage` and calling it out in the instrumentation README.

### Write comprehensive automated tests

Code that is not tested will not be accepted by maintainers. We understand that providing 100% test coverage is not always possible but we still ask that you provide your best effort when writing automated tests.

Most of the libraries instrument introduce changes outside of our control. For this reason, integration or state-based tests are preferred over interaction (mock) tests.

When you do in fact run into cases where test doubles or API stubs are absolutely necessary, we recommend using the [`rspec-mocks`](https://github.com/rspec/rspec-mocks) and [`webmocks`](https://github.com/bblimke/webmock) gems.

### Understand performance characteristics

The OTel Specification describes expectations around the performance of SDKs, which you must review and apply to instrumentation: <https://opentelemetry.io/docs/specs/otel/performance/>

Instrumentation libraries should be as lightweight as possible and must:

* Rely on `rubocop-performance` linters to catch performance issues
* Consider using [microbenchmarks](https://github.com/evanphx/benchmark-ips) and [profiling](https://ruby-prof.github.io/) to address any possible performance issues
* Provide minimal solutions and code paths

#### Provide minimal solutions and code paths

Instrumentation should have the minimal amount of code necessary to provide useful insights to our users. It may sound contrary to good engineering practices, but you must avoid adding lots of small methods, classes, and objects when instrumenting a library.

Though often easier to maintain and reason about; small and well-factored code adds overhead to the library you're instrumenting, resulting in performance degradation due to unnecessary object allocations, method dispatching, and other performance overhead.

It also contributes to building large backtraces, making it more difficult for our end users to understand the essential parts of exception reports. That will likely result in additional filtering logic in their application to avoid reporting unnecessary stack frames.

In cases when code uses monkey patching, it runs the risk of _adding_ methods that conflict with the internal implementation of the library and may result in unexpected behavior and bugs.

Avoid instrumenting _every_ method in a library and instead focus on the methods that provide the _most_ insights into what typically causes performance problems for applications, e.g. I/O and network calls. The use case for this type of low-level granularity falls under the purview of profiling.

In the near future, [OTel Profiling](https://opentelemetry.io/blog/2024/profiling/) will provide users an even deeper understanding of what is happening in their applications at a more granular level.

Here are some examples of performance fixes that reduced object allocations and method dispatching:

* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/867>
* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/723>
* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/665>
* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/642>
* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/207>
* <https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/232>

#### Avoid adding custom extensions

Though your instrumentation may accept configurations options to customize the output, you should consider that the more options you add, the more complexity you will have to manage.

You should _avoid_ adding options that allow custom code blocks (`type: :callable`) to be executed as part of the instrumentation. It is often difficult to predict error modes and the performance impact custom code will have on your instrumentation, which in turn will impact the service being instrumented.

You should steer users towards post-processing as part of the [OTel Collector](https://opentelemetry.io/docs/collector/), which has a richer and more powerful toolset, and executes out of the application's critical code path.

## Enable CI

This project contains multiple CI workflows that execute tests and ensure the gems are installable.

### Standalone instrumentation

For standalone instrumentation that does not have any external service dependencies, add the gem to the `/.github/workflows/ci-instrumentation.yml` file under `jobs/instrumentation/strategy/matrix/gem`:

``` yaml

jobs:
  instrumentation:
    strategy:
      fail-fast: false
      matrix:
        gem:
          - action_pack
          - action_view
          - active_job
          # ...
          - werewolf
        os:
          - ubuntu-latest

```

#### JRuby Compatibility

If your gem is incompatible with `JRuby`, you can exclude it from the matrix by adding an entry to the `/.github/workflows/ci-instrumentation.yml` file under `jobs/instrumentation/steps/[name="JRuby Filter"]`:

``` yaml
      - name: "JRuby Filter"
        id: jruby_skip
        shell: bash
        run: |
          echo "skip=false" >> $GITHUB_OUTPUT
          [[ "${{ matrix.gem }}" == "action_pack"              ]] && echo "skip=true" >> $GITHUB_OUTPUT
          # ...
          [[ "${{ matrix.gem }}" == "werewolf"                     ]] && echo "skip=true" >> $GITHUB_OUTPUT
          # This is essentially a bash script getting evaluated, so we need to return true or the whole job fails.
          true
```

### External service instrumentations

Adding jobs for instrumentation with external service dependencies may be a bit more difficult if the job does not already have a similar service configured.

#### Using Existing Services

CI is currently configured to support the following services:

* kafka
* memcached
* mongodb
* mysql
* postgresql
* rabbitmq
* redis

If your gem depends on one of those services, then great! The next step is to add the gem to matrix in the `/.github/workflows/ci-service-instrumentation.yml` file under `jobs/instrumentation_*/strategy/matrix/gem`:

```yaml

  instrumentation_kafka:
    strategy:
      fail-fast: false
      matrix:
        gem:
          - racecar
          - rdkafka
          - ruby_kafka
          - werewolf
        os:
          - ubuntu-latest
```

#### Adding a New Service

Assuming your external service is not supported, you may consider adding it as a new job in the `/.github/workflows/ci-service-instrumentation.yml` file, however we will accept new services on a case-by-case basis.

Add the service container to `jobs/instrumentation_with_services/services` and add the gem to the matrix in `jobs/instrumentation_with_services/strategy/matrix/gem`:

```yaml

  instrumentation_with_services:
    strategy:
      fail-fast: false
      matrix:
        gem:
          - dalli
          - mongo
          - werewolf
        os:
          - ubuntu-latest
    services:
      # ...
      my_service:
        image: my_service:latest
        # ...
```

> :information_source: Please refer to the official [GitHub Actions Documentation](https://docs.github.com/en/actions/using-containerized-services/about-service-containers) for more information on how to add a service container.

If we determine the service container slows down the test suite significantly, it may make sense to copy the marix and steps stanzas from an existing instrumentation and update it to use the new service container as a dependency:

```yaml

  instrumentation_silver:
    strategy:
      fail-fast: false
      matrix:
        gem:
          - werewolf
        os:
          - ubuntu-latest
    name: other / ${{ matrix.gem }} / ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: "Test Ruby 3.3"
        uses: ./.github/actions/test_gem
        with:
          gem: "opentelemetry-instrumentation-${{ matrix.gem }}"
          ruby: "3.3"
      - name: "Test Ruby 3.2"
        uses: ./.github/actions/test_gem
        with:
          gem: "opentelemetry-instrumentation-${{ matrix.gem }}"
          ruby: "3.2"
      - name: "Test Ruby 3.1"
        uses: ./.github/actions/test_gem
        with:
          gem:  "opentelemetry-instrumentation-${{ matrix.gem }}"
          ruby: "3.1"
      - name: "Test Ruby 3.0"
        uses: ./.github/actions/test_gem
        with:
          gem:  "opentelemetry-instrumentation-${{ matrix.gem }}"
          ruby: "3.0"
          yard: true
          rubocop: true
          build: true
      - name: "Test JRuby"
        uses: ./.github/actions/test_gem
        with:
          gem:  "opentelemetry-instrumentation-${{ matrix.gem }}"
          ruby: "jruby-9.4.2.0"
    services:
      # ...
      my_service:
        image: my_service:latest
        # ...
```

## Documentation

### README and Yardoc

The `instrumentation_generator` creates a `README.md` file for your instrumentation. Please ensure that the `README` is up-to-date and contains the following:

1. The span names, events, and semantic attributes emitted by the instrumentation
2. The configuration options available
3. Any known limitations or caveats
4. The minimum supported gem version

> :information_source: See the `ActiveJob` instrumentation [`README`](./active_job/README.md) for a comprehensive example.

In addition to that, there should also be redundant `yardoc` comments in the entrypoint of your gem, i.e. the subclass `OpenTelemetry::Instrumentation::Base`.

> :information_source: See the `Sidekiq::Instrumentation` [class description](./sidekiq/lib/opentelemetry/instrumentation/sidekiq/instrumentation.rb) for a comprehensive example. 

### Examples

Executuable examples should be included in the `examples` directory that demonstrate how to use the instrumentation in a real-world scenario.

We recommend using [Bundler's inline gemfile](https://bundler.io/guides/bundler_in_a_single_file_ruby_script.html) to run the examples. Here is an example from the `grape` instrumentation:

```ruby

# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'grape', '~> 1.2'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rack'
  gem 'opentelemetry-instrumentation-grape'
end

# Export traces to console
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'trace_demonstration'
  c.use_all # this will only require instrumentation gems it finds that are installed by bundler.
end

at_exit do
  OpenTelemetry.tracer_provider.shutdown
end

# A basic Grape API example
class ExampleAPI < Grape::API
  format :json

  desc 'Return a greeting message'
  get :hello do
    { message: 'Hello, world!' }
  end

  desc 'Return information about a user'
  params do
    requires :id, type: Integer, desc: 'User ID'
  end
  get 'users/:id' do
    { id: params[:id], name: 'John Doe', email: 'johndoe@example.com' }
  end
end

# Set up fake Rack application
builder = Rack::Builder.app do
  # Integration is automatic in web frameworks but plain Rack applications require this line.
  # Enable it in your config.ru.
  use *OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.middleware_args
  run ExampleAPI
end
app = Rack::MockRequest.new(builder)

app.get('/hello')
app.get('/users/1')

```

## Submit a pull request

You are encouraged to submit a `draft` pull request early in the development process to get feedback from the maintainers, run your tests via CI, and ensure that your changes are in line with the project's goals.

The `CODEOWNERS` is used to notify instrumentation authors when a pull request is opened. Please add yourself to the `instrumentation` section of the `CODEOWNERS` file, e.g.

```plaintext

instrumentation/werewolf/ @lycanthrope @open-telemetry/ruby-contrib-maintainers @open-telemetry/ruby-contrib-approvers

```

> :information_source: In order for you to receive a request to review PRs, you must be a member of the [`open-telemetry/community`](https://github.com/open-telemetry/community/blob/5db097b38ce930fb1ff3eb79a1625bae46136894/community-membership.md#community-membership). Please consider applying for membership if you are not already a member.

The [CONTRIBUTING.md](../CONTRIBUTING.md) guide has the remaining steps to get your contribution reviewed, merged, and released.
