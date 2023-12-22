# Release History: opentelemetry-instrumentation-sidekiq

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259)) ([b0d5aa6](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b0d5aa68dd660546d28f8f89ef9004ec776c7bf6))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* Allow traces inside jobs while avoiding Redis noise ([#580](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/580)) ([13c05ce](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/13c05ceeed804d0cae83a8944fd893565d38fe5d))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* make sidekiq instrumentation compatible with sidekiq 6.5.0 ([#1304](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1304)) ([3d7ee98](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3d7ee98418ac8c9cff6f0e302e42c8ce1e752f89))
* make sidekiq instrumentation rake task compatible with TruffleRuby ([#60](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/60)) ([c71dda0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c71dda0a74c640cbc9ed4c704fbda11269bfdb7f))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.25.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.24.4 / 2023-08-07

* FIXED: Allow traces inside jobs while avoiding Redis noise

### v0.24.3 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.24.2 / 2023-07-21

* ADDED: Update `opentelemetry-common` from [0.19.3 to 0.20.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/537)

### v0.24.1 / 2023-06-05

* FIXED: Base config options 

### v0.24.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.23.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 

### v0.22.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.22.0 / 2022-06-09

* Upgrading Base dependency version

### v0.21.1 / 2022-06-09

* FIXED: Broken test file requirements 
* FIXED: Make sidekiq instrumentation compatible with sidekiq 6.5.0 

### v0.21.0 / 2022-05-02

* ADDED: Validate Using Enums 
* FIXED: RubyGems Fallback 

### v0.20.2 / 2021-12-02

* (No significant changes)

### v0.20.1 / 2021-09-29

* (No significant changes)

### v0.20.0 / 2021-08-18

* ADDED: Gracefully flush provider on sidekiq shutdown event 

### v0.19.1 / 2021-08-12

* (No significant changes)

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Sidekiq propagation config 
  - Config option enable_job_class_span_names renamed to span_naming and now expects a symbol of value :job_class, or :queue
  - The default behaviour is no longer to have one continuous trace for the enqueue and process spans, using links is the new default.  To maintain the previous behaviour the config option propagation_style must be set to :child.
* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Sidekiq propagation config 
* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* TEST: update test for redis instrumentation refactor [#760](https://github.com/open-telemetry/opentelemetry-ruby/pull/760)
* BREAKING CHANGE: Remove optional parent_context from in_span

* FIXED: Remove optional parent_context from in_span
* FIXED: Instrument Redis more thoroughly by patching Client#process.

### v0.17.0 / 2021-04-22

* ADDED: Accept config for sidekiq peer service attribute

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

* ADDED: Instrument sidekiq background work
* FIXED: Adjust Sidekiq middlewares to match semantic conventions
* FIXED: Set minimum compatible version and use untraced helper

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* (No significant changes)

### v0.7.0 / 2020-10-07

* DOCS: Adding README for Sidekiq instrumentation
* DOCS: Remove duplicate reference in Sidekiq README
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
