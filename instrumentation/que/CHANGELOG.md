# Release History: opentelemetry-instrumentation-que

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* add support for `job_options` argument ([#57](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/57)) ([47812af](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/47812af5fc67b22ada1d4749ecdf52532ccf107a))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* Drop Rails dependency for ActiveSupport Instrumentation ([#242](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/242)) ([c571ece](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c571ecee6283e877fb7df3ea2b01acf722410551))
* **que:** Correctly set bulk_enqueue job options ([#573](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/573)) ([cf5f236](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/cf5f236e91252bf9d399f8862de6f06d36b5d03d))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* remove `job_options` when using `bulk_enqueue` ([#205](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/205)) ([6e89c92](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6e89c92f189bc6e187da06ea2af4e38531b93601))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.7.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.7.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.6.2 / 2023-08-07

* FIXED: Correctly set bulk_enqueue job options

### v0.6.1 / 2023-06-05

* FIXED: Base config options 

### v0.6.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 
* FIXED: Drop Rails dependency for ActiveSupport Instrumentation 

### v0.5.1 / 2023-01-14

* FIXED: Remove `job_options` when using `bulk_enqueue` 
* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.5.0 / 2022-10-28

* ADDED: Add support for `job_options` argument

### v0.4.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.3.0 / 2022-05-02

* ADDED: Validate Using Enums 
* FIXED: RubyGems Fallback 

### v0.2.0 / 2021-12-01

* ADDED: Instrument Que poller 

### v0.1.1 / 2021-09-29

* (No significant changes)

### v0.1.0 / 2021-09-15

* Initial release.
