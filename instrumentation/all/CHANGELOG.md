# Release History: opentelemetry-instrumentation-all

### v0.50.1 / 2023-09-07

* FIXED: Align messaging instrumentation operation names (Resque)

### v0.50.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.40.0 / 2023-08-07

* ADDED: Add Gruf instrumentation

### v0.39.1 / 2023-06-05

* FIXED: Use latest bug fix version for all dependencies

### v0.39.0 / 2023-06-02

* BREAKING CHANGE: Separate logical MySQL host from connected host
* ADDED: Separate logical MySQL host from connected host

### v0.38.0 / 2023-05-31

* BREAKING CHANGE: Add database name for trilogy traces

* ADDED: Add database name for trilogy traces

### v0.37.0 / 2023-05-25

* ADDED: Add config[:obfuscation_limit] to pg and mysql2
* ADDED: Add Obfuscation Limit Option to Trilogy


### v0.36.0 / 2023-05-18

* ADDED: GraphQL instrumentation: support new tracing API (#453)
* ADDED: Add span_preprocessor hook (#456)
* ADDED: add db.operation attribute for dalli (#458)

### v0.35.0 / 2023-04-21

* ADDED: Re-add Grape instrumentation to opentelemetry-instrumentation-all

### v0.34.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7
* ADDED: Add Grape instrumentation

### v0.33.0 / 2023-03-15

* BREAKING CHANGE: Add support for GraphQL 2.0.19

* FIXED: Add support for GraphQL 2.0.19

### v0.32.0 / 2023-03-13

* BREAKING CHANGE: Lock graphql max version to 2.0.17
* FIXED: Lock graphql max version to 2.0.17
* ADDED: Add with_attributes context propagation to Trilogy instrumentation
* ADDED: Add option to configure span name for trilogy
* FIXED: Ensure encoding errors handled during SQL obfuscation for Trilogy

### v0.31.0 / 2023-02-09

* BREAKING CHANGE: Drop Rails 5 support [#324](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/324)


### v0.30.0 / 2023-01-31

* BREAKING CHANGE: Updates instrumentations [#303](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/303)

### v0.29.0 / 2023-01-14

* BREAKING CHANGE: includes minor version updates in [#271](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/271)

### v0.28.1 / 2023-01-14

* DOCS: Fix gem homepage
* DOCS: More gem documentation fixes

### v0.28.0 / 2022-11-09

* ADDED: Bump minimum gem versions for opentelemetry-instrumentation-all
* ADDED: Instrumentation for racecar
* CHANGED: Update rails instrumentation

### v0.27.0 / 2022-10-14

* CHANGED: Update Rails instrumentation

### v0.26.0 / 2022-10-12

* ADDED: Upgrade min instrumentation versions See For Details https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/134

### v0.25.0 / 2022-06-09

* Bump all dependencies to use base 0.21.0

### v0.24.1 / 2022-05-05

* (No significant changes)

### v0.24.0 / 2022-05-02

* ADDED: Adds instrumentation for rdkafka
* FIXED: Add rdkafka to all

### v0.23.0 / 2022-01-26

* ADDED: Add Trilogy Auto Instrumentation
* FIXED: `ActiveSupport` constant conflict in Active Model Serializers instrumentation
* FIXED: add missing require for aws_sdk instrumentation #1054

### v0.22.0 / 2021-12-01

* ADDED: Move activesupport notification subsciber out of action_view gem

### v0.21.3 / 2021-10-07

* (No significant changes)

### v0.21.2 / 2021-09-29

* (No significant changes)

### v0.21.1 / 2021-09-29

* (No significant changes)

### v0.21.0 / 2021-09-15

* ADDED: Add Que instrumentation

### v0.20.2 / 2021-09-09

* (No significant changes)

### v0.20.1 / 2021-08-18

* FIXED: Instrumentation all sidekiq

### v0.20.0 / 2021-08-12

* ADDED: Instrument active record
* ADDED: Add ActionView instrumentation via ActiveSupport::Notifications

### v0.19.0 / 2021-06-25

* ADDED: Add resque instrumentation
* ADDED: Add ActiveJob instrumentation
* ADDED: Configuration option to enable or disable redis root spans [#777](https://github.com/open-telemetry/opentelemetry-ruby/pull/777)
* FIXED: Broken instrumentation all release

### v0.18.0 / 2021-05-21

* ADDED: Add koala instrumentation

### v0.17.0 / 2021-04-22

* ADDED: Add instrumentation for postgresql (pg gem)

### v0.16.0 / 2021-03-17

* ADDED: Instrument http gem
* ADDED: Instrument lmdb gem
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Instrument http client gem

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.1 / 2021-01-13

* ADDED: Instrument RubyKafka

### v0.12.0 / 2020-12-24

* ADDED: Instrument graphql

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* FIXED: Otel-instrumentation-all not installing all

### v0.9.0 / 2020-11-27

* ADDED: Add common helpers

### v0.8.0 / 2020-10-27

* (No significant changes)

### v0.7.0 / 2020-10-07

* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* Now depends on version 0.6.x of all the individual instrumentation gems.
