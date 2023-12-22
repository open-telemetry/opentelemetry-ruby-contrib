# Release History: opentelemetry-instrumentation-base

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* GraphQL instrumentation: support new tracing API ([#453](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/453))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))
* This requires upgrading both the SDK and Instrumentation gem in tandem

### Features

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* GraphQL instrumentation: support new tracing API ([#453](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/453)) ([5d87786](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/5d87786984b42e795af4646a3e9ca240c56573e9))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))
* Use Registry Gem ([#1220](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1220)) ([e533817](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/e533817ba387bbfd6270e5c4d0ae42452dd7d9dc))

### v0.22.3 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.22.2 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.22.1 / 2023-06-02

* feat: make config available to compatible blocks #453

### v0.22.0 / 2023-04-16

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7

### v0.21.1 / 2023-01-14

* DOCS: Fix gem homepage
* DOCS: More gem documentation fixes

### v0.21.0 / 2022-05-26

* BREAKING CHANGE: This requires upgrading both the SDK and Instrumentation gem in tandem


### v0.20.0 / 2022-05-02

* ADDED: Validate Using Enums
* FIXED: RubyGems Fallback

### v0.19.0 / 2021-12-01

* ADDED: Add default options config helper + env var config option support

### v0.18.3 / 2021-09-29

* (No significant changes)

### v0.18.2 / 2021-08-12

* (No significant changes)

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* FIXED: Missing instrumentation classes during configuration

### v0.17.0 / 2021-04-22

* Initial release.
