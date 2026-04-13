# Developer Guide

## Scaffolding new Gem

### Using Instrumentation Generator

This repository contains a script to generate a new instrumentation library.

The snippet below demonstrates how to generate an instrumentation for the `werewolf` gem, starting from the repository root.

```console

$bash opentelemetry-ruby-contrib> bin/instrumentation_generator werewolf

```

The output of the generator shows that it creates a new directory in the `instrumentation` directory using the name of the gem:

```console

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

### Manually

TBC

## Adding gem to processes

### CI

To add the gem to the CI processes the gem needs to be added to the `matrix.gem` object of the `.github/workflows/ci-instrumentation.yml` when not using services and if it requires services it goes in `.github/workflows/ci-instrumentation-with-services.yml`:

```yaml
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

### Labeler

TBC

### Component owners

TBC

## Testing with Services

### Adding new Services

Assuming that the required external service is not already supported, you will need to define it as a infra service in the `/.docker/infra/{{service_name}}` directory. 
This directory will contain a single file `compose.yml` which acts as the service definition. 

An example of this service is:

```yaml
services:
  rabbitmq:
    image: rabbitmq:4.2.5-alpine@sha256:53e51f8469ef13d0a1a2b03c0d36dcf4efbf13089f552440ec5620ca07f2c64e
    ports:
      - "5672:5672"
```

This compose file when run using docker will produce a single runnable service.
This service needs to be included in the root compose file `docker-compose.yml`.

The final step in adding a new service is to define a renovate package rule to `.github/renovate.json5` which manages the min major version of the service tested against.

```json
    {
      description: "Wait until current major postgres is EoL before updating",
      dependencyDashboardCategory: "Min Docker service",
      matchUpdateTypes: ["major"],
      matchDepNames: ["postgres"],
      minimumReleaseAge: "1460 days",
    },
```

The `minimumReleaseAge` days value should be calculated based on the expected age of the major version when it becomes the lowest major version which is not end of life.
In the above example, we wait until a major version has been available for 1460 days (4 years) which is calculated based on each major version of Postgres being supported for 5 years with a new major each year.
Hence 5 years - 1 year = 4 years which works out to be the 1460 days.

### Using service to test

Once the required infra services have been defined as described in [Adding new services](#adding-new-services), a `compose.yml` needs to be defined within the test folder.

This `compose.yml` file in most cases will just be:

```yaml
include:
  - ../../../.docker/infra/rabbitmq/docker-compose.yml
```

Lastly to ensure that pr's are labelled with the gems affected by changes an infra service, the path to the to infra service needs to be added labeler setup (`.github/labeler.yml`) for the gem as per below.

```yaml
instrumentation-warewolf:
  - changed-files:
      - any-glob-to-any-file:
          - "instrumentation/warewolf/**"
          - ".docker/infra/rabbitmq/**"
```

## Showcasing functionality via examples

Executable examples should be included in the `examples` directory that demonstrate how to use the instrumentation in a real-world scenario.

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

## Freezing Gem Development

### Adding notice to Readme

#### Upstream abbandoned

When the upstream library has not seen activity for an extended period of time XYZ months, we will freeze our development efforts on this gem.
When this occurs we are to add the folloing notice to the readme of this gem:

> [!IMPORTANT]
>
> **Deprecation Notice:**
> This gem is deprecated due to the library ({{library}}) it relies on no longer being maintained. The code remains available for reference, but no further updates or fixes will be provided. Users should consider migrating to actively supported alternatives.

#### Upstream added native support

When the upstream library adds native instrumentation, this is an indicator that we can freeze our development efforts on this gem.
When this occurs we are to add the following notice to the readme:

> [!NOTE]
>
> **Development Frozen:**
>
> {{library}} {{version}}+ includes native OpenTelemetry instrumentation. For the best experience and continued support, we recommend:
>
> - **{{library}} < {{version}}**: Use `{{GEM}}` gem
> - **{{library}} ≥ {{version}}**: Use {{library}}'s built-in OpenTelemetry support (remove `{{GEM}}` gem)
>
> Community instrumentation is compatible with {{library}} versions up to {{version}}. Development of this gem is frozen for newer {{library}} versions in favor of the native integration.

Where gem is this gem and library is what we are instrumenting.

### Blocking automated dependency updates

Currently we use Renovate to provide automated pr's which update our dependencies, however in the scenario where a Gem development is frozen,
we do not want these updates just for this gem.

To achieve this the path of the gem need to be added to the `ignorePaths` property of `.github/renovate.json5`.

The key thing is that this will block renovate from updating that gem directory while still allowing all updates to proceed.

### Pinning infra services

Due to the nature of using shared service definitions it will be necessary to copy the shared service folder ie `.docker/rabbitmq` into a newly created `.docker` folder at the root of the gem.
Following this copying of the services, the references in the gem's compose files need to be updated to use the local copy.

This processes ensures that if the service is updated the frozen gem remains using the last version supported/tested.

### Adding deprecation label to pr's

To help with PR review, the gem path should be added to the deprecated label block in `.github/labeler.yml` which ensures that if changes to deprecated gems occur,
they are labelled accordingly.

## Removing Gems

### Removal Checklist

TBC

### Steps to be performed

When a gem is ready to be removed, there is a couple of additional steps to be performed so that we achieve a complete removal.
These steps are:

- Remove the gem block from `.github/labeler.yml`
- Remove the gem path from the deprecated label path in `.github/labeler.yml`
- Remove the gem path from the `AllCops.Exclude` property in `.rubocop.yml`
- Remove the gem block from `.toys/.data/releases.yml`
- Remove the gem path from ignore path block in `.github/renovate.json5`
- Close any open issues for which only apply to the gem
- Remove the gem label from any issues which affect multiple gems
- Remove the component from `.github/component_owners.yml`
