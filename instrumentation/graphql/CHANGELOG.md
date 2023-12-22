# Release History: opentelemetry-instrumentation-graphql

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* GraphQL instrumentation: support new tracing API ([#453](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/453))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Add support for GraphQL 2.0.19 ([#379](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/379))
* Lock graphql max version to 2.0.17 ([#375](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/375))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* GraphQL instrumentation: support new tracing API ([#453](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/453)) ([5d87786](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/5d87786984b42e795af4646a3e9ca240c56573e9))
* Normalize GraphQL span names for easier aggregation analysis ([#291](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/291)) ([738f14a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/738f14a39339d8226d5a417d76975c58e2f0e312))


### Bug Fixes

* Add support for GraphQL 2.0.19 ([#379](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/379)) ([653d422](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/653d422989f10dedf6784f553940c9dd9202b6a0))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* GraphQL resolve_type_lazy ([#512](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/512)) ([ed03835](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/ed038358d63b3fbeb66d33ccf21f3f0414312127))
* GraphQL tests and installation ([#572](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/572)) ([052f78f](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/052f78f5ac29df967f4aa94b5c87ad16d11b978b))
* GraphQL tracing ([#482](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/482)) ([2614600](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/2614600916338a5a3a13f56bb9cea0daccb5f9d0))
* GraphQL validate events ([#557](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/557)) ([e749ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/e749ff7e234dca78dc25f38226cf4f2328b952ce))
* improve GraphQL tracing compatibility with other tracers ([#618](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/618)) ([c308b95](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c308b95b34e16a72dc744fd57cc705183d15956f))
* Lock graphql max version to 2.0.17 ([#375](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/375)) ([f1c1125](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/f1c112529bce28a2dbbbfa01df80b5a0a7bbdb93))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))
* Use semantic graphql attribute names ([#73](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/73)) ([9bdcd06](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/9bdcd06e03d74b33f9470c2972b66a573876ac5f))


### Performance Improvements

* **graphql:** cache attribute hashes ([#723](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/723)) ([a7f6111](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a7f6111e769b5547cae5291765b4c45318ff6fdf))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.27.0 / 2023-11-28

* CHANGED: Performance optimization cache attribute hashes [#723](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/723)

### v0.26.8 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.26.7 / 2023-09-27

* FIXED: Micro optimization: build Hash w/ {} (https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/665)

### v0.26.6 / 2023-08-26

* FIXED: Improve GraphQL tracing compatibility with other tracers

### v0.26.5 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.26.4 / 2023-08-01

* FIXED: GraphQL tests and installation

### v0.26.3 / 2023-07-29

* FIXED: GraphQL validate events

### v0.26.2 / 2023-06-05

* FIXED: Base config options 
* FIXED: GraphQL resolve_type_lazy 

### v0.26.1 / 2023-05-30

* FIXED: GraphQL tracing

### v0.26.0 / 2023-05-17

* BREAKING CHANGE: GraphQL instrumentation: support new tracing API 

* ADDED: GraphQL instrumentation: support new tracing API

### v0.25.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.24.0 / 2023-03-15

* BREAKING CHANGE: Add support for GraphQL 2.0.19

* FIXED: Add support for GraphQL 2.0.19

### v0.23.0 / 2023-03-13

* BREAKING CHANGE: Lock graphql max version to 2.0.17

* FIXED: Lock graphql max version to 2.0.17

### v0.22.0 / 2023-01-27

* ADDED: Normalize GraphQL span names for easier aggregation analysis 

### v0.21.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.21.0 / 2022-07-12

* FIXED: Use semantic graphql attribute names 

### v0.20.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.19.3 / 2022-05-05

* (No significant changes)

### v0.19.2 / 2021-12-02

* (No significant changes)

### v0.19.1 / 2021-09-29

* (No significant changes)

### v0.19.0 / 2021-08-12

* ADDED: Add support for graphql errors 
* DOCS: Update docs to rely more on environment variable configuration 

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* Initial release.
