# Release History: opentelemetry-instrumentation-net_http

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* add net http instrumentation hooks config ([#62](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/62)) ([d9842bf](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/d9842bf145aceb702777e294b29e7480d41e900b))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))


### Bug Fixes

* add untraced check to the Net::HTTP connect instrumentation ([#213](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/213)) ([a014481](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a014481f965caed5c8411cfd5b20c07ebba543b4))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* clientcontext attrs overwrite in net::http ([#1114](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1114)) ([dcf02c8](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/dcf02c8c9c91b400e42f071d54069ef5b2c6eb94))
* Drop Rails dependency for ActiveSupport Instrumentation ([#242](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/242)) ([c571ece](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c571ecee6283e877fb7df3ea2b01acf722410551))
* excessive hash creation on context attr merging ([#1117](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1117)) ([bc1291a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc1291a000abf2a27421bc4d5596d59d142e4055))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Rename HTTP CONNECT for low level connection spans ([#129](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/129)) ([efe59ff](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/efe59ffa50c88689199ad2132aa920b778bd0a67))
* Update `Net::HTTP` instrumentation to no-op on untraced contexts ([#722](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/722)) ([3b8ec51](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b8ec5182c915e5a3be3bc5ce0baf4e91182d2fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.22.4 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.22.3 / 2023-11-22

* FIXED: Update `Net::HTTP` instrumentation to no-op on untraced contexts

### v0.22.2 / 2023-07-21

* ADDED: Update `opentelemetry-common` from [0.19.3 to 0.20.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/537)

### v0.22.1 / 2023-06-05

* FIXED: Base config options 

### v0.22.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 
* FIXED: Drop Rails dependency for ActiveSupport Instrumentation 

### v0.21.1 / 2023-01-14

* FIXED: Add untraced check to the Net::HTTP connect instrumentation 
* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.21.0 / 2022-10-04

* ADDED: Add Net::HTTP :untraced_hosts option
* FIXED: Rename HTTP CONNECT for low level connection spans 

### v0.20.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.19.5 / 2022-05-05

* (No significant changes)

### v0.19.4 / 2022-02-02

* FIXED: Clientcontext attrs overwrite in net::http 
* FIXED: Excessive hash creation on context attr merging 

### v0.19.3 / 2021-12-01

* FIXED: Change net attribute names to match the semantic conventions spec for http 

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add Net::HTTP#connect tracing

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* ADDED: Add common helpers

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Added documentation for net_http gem in instrumentation
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
