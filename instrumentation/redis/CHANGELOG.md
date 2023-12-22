# Release History: opentelemetry-instrumentation-redis

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* redis-rb 5.0 and redis-client support ([#121](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/121)) ([0063fc1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/0063fc10ca307d4f147ec5c0ecc1a9969b989a2f))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* add appraisals for redis 4.2-4.6 ([#1181](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1181)) ([e55c76a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/e55c76a07f9ed0914690cc40e1ff256604aefce1))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* prevent redis instrumentation from mutating the command ([#1116](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1116)) ([13cad75](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/13cad751d45211a74a25592eee06d37008eef210))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.25.3 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.25.2 / 2023-07-21

* ADDED: Update `opentelemetry-common` from [0.19.3 to 0.20.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/537)

### v0.25.1 / 2023-06-05

* FIXED: Base config options 

### v0.25.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.24.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.24.0 / 2022-09-14

* ADDED: Redis-rb 5.0 and redis-client support 

### v0.23.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.22.1 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.22.0 / 2022-05-02

* ADDED: Validate Using Enums 
* FIXED: Add appraisals for redis 4.2-4.6 

### v0.21.3 / 2022-02-02

* FIXED: Prevent redis instrumentation from mutating the command 

### v0.21.2 / 2021-12-01

* (No significant changes)

### v0.21.1 / 2021-09-29

* (No significant changes)

### v0.21.0 / 2021-08-12

* ADDED: Add toggle for redis db.statement attribute 

### v0.20.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.19.0 / 2021-05-28

* ADDED: Configuration option to enable or disable redis root spans [#777](https://github.com/open-telemetry/opentelemetry-ruby/pull/777)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
refactor: redis attribute utils [#760](https://github.com/open-telemetry/opentelemetry-ruby/pull/760)
refactor: simplify redis attribute assignment [#758](https://github.com/open-telemetry/opentelemetry-ruby/pull/758)
test: split redis instrumentation test [#754](https://github.com/open-telemetry/opentelemetry-ruby/pull/754)
* ADDED: Option to obfuscate redis arguments
* FIXED: Instrument Redis more thoroughly by patching Client#process.

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* FIXED: Update DB semantic conventions
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* ADDED: Accept config for redis peer service attribute
* ADDED: Move utf8 encoding to common utils
* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Semantic conventions db.type -> db.system

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Redis attribute propagation
* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Added redis documentation
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
