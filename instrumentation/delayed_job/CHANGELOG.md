# Release History: opentelemetry-instrumentation-delayed_job

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop DelayedJob ActiveRecord in Tests ([#685](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/685))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))


### Bug Fixes

* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* Drop DelayedJob ActiveRecord in Tests ([#685](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/685)) ([fc5a75f](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/fc5a75f16951ae434aa973a4ae07017fddcd38e5))
* Rails 7.0.3 test suite incompatibility ([#1236](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1236)) ([c8e89e8](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c8e89e802bc302ede08bb33657cd3152a492fda9))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.22.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.22.0 / 2023-10-16

* BREAKING CHANGE: Drop DelayedJob ActiveRecord in Tests

* FIXED: Drop DelayedJob ActiveRecord in Tests

### v0.21.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.20.1 / 2023-06-05

* FIXED: Base config options 

### v0.20.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.19.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.19.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Rails 7.0.3 test suite incompatibility 
* FIXED: Broken test file requirements 

### v0.18.5 / 2022-05-02

* FIXED: RubyGems Fallback 

### v0.18.4 / 2021-12-02

* (No significant changes)

### v0.18.3 / 2021-09-29

* (No significant changes)

### v0.18.2 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* BREAKING CHANGE: Replace Time.now with Process.clock_gettime

### v0.17.0 / 2021-04-22

* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* (No significant changes)

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

* FIXED: Coerce message ID to string in span payload

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-10-07

* Initial release of Delayed Job instrumentation (ported from Datadog)
