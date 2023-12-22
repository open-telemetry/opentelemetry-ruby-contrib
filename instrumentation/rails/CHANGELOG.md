# Release History: opentelemetry-instrumentation-rails

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259))
* Update Instrumentations ([#303](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/303))
* remove enable_recognize_route and span_naming options ([#214](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/214))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259)) ([b0d5aa6](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b0d5aa68dd660546d28f8f89ef9004ec776c7bf6))
* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680)) ([3f44472](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3f44472230964017d1831a47ea0661dc92d55909))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* name ActionPack spans with the HTTP method and route ([#123](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/123)) ([4a65b3d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/4a65b3d7f76603eba1d958964c64093f47846929))
* OTel Railtie ([#1111](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1111)) ([dc25f73](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/dc25f73b85ec0684008d7927559cf44e2a2429ec))
* Update Instrumentations ([#303](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/303)) ([5441260](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/54412608511e42591f5775e1d805682147e3bb94))


### Bug Fixes

* Add Rails 7.1 compatability ([#684](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/684)) ([93dcf35](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/93dcf359a8a66d17fed545f7a642f1d3a83d4ef4))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* bump rails instrumentation dependency on action_pack instrumentation ([#175](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/175)) ([e3b9e0e](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/e3b9e0e197ff0cb5c489c77d27fb5be23052797c))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* remove enable_recognize_route and span_naming options ([#214](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/214)) ([ea604aa](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/ea604aa77e0d4c26e1d178877dea75c795f039ee))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.29.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.29.0 / 2023-11-22

* BREAKING CHANGE: Drop Rails 6.0 EOL

* ADDED: Drop Rails 6.0 EOL

### v0.28.1 / 2023-10-16

* FIXED: Add Rails 7.1 compatibility

### v0.28.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.27.1 / 2023-06-05

* FIXED: Use latest bug fix version for all dependencies

### v0.27.0 / 2023-06-05

* FIXED: Base config options
* FIXED: Upgrade ActionPack and ActionView min versions

### v0.26.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7

### v0.25.0 / 2023-02-08

* BREAKING CHANGE: Update Instrumentations GraphQL, HttpClient, Rails [#303](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/303)
* BREAKING CHANGE: Drop Rails 5 Support [#315](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/315)

* DOCS: Rails Instrumentation Compatibility

### v0.24.1 / 2023-01-14

* DOCS: Fix gem homepage

### v0.24.0 / 2022-12-06

* BREAKING CHANGE: Remove enable_recognize_route and span_naming options

* FIXED: Remove enable_recognize_route and span_naming options

### v0.23.1 / 2022-11-08

* FIXED: Bump rails instrumentation dependency on action_pack instrumentation

### v0.23.0 / 2022-10-14

* ADDED: Name ActionPack spans with the HTTP method and route

### v0.22.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements

### v0.21.0 / 2022-05-02

* ADDED: OTel Railtie
* FIXED: RubyGems Fallback

### v0.20.0 / 2021-12-01

* ADDED: Move activesupport notification subsciber out of action_view gem
* FIXED: Instrumentation of Rails 7

### v0.19.4 / 2021-10-06

* (No significant changes)

### v0.19.3 / 2021-09-29

* (No significant changes)

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-09-09

* (No significant changes)

### v0.19.0 / 2021-08-12

* ADDED: Instrument active record
* ADDED: Add ActionView instrumentation via ActiveSupport::Notifications
* FIXED: Rails instrumentation to not explicitly install sub gems
* DOCS: Update docs to rely more on environment variable configuration

* This release adds support for Active Record and Action View.
* The `enable_recognize_route` configuration option has been moved to the ActionPack gem.
* See readme for details on how to configure the sub instrumentation gems.

### v0.18.1 / 2021-06-23

* FIXED: Updated rack middleware position to zero

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* ADDED: Added http.route in rails instrumentation to match the spec
* FIXED: Rails example by not using `rails` from git
* FIXED: Updated rack middleware position to zero

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* (No significant changes)

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Rails tests
* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* FIXED: Otel-instrumentation-all not installing all

### v0.9.0 / 2020-11-27

* Initial release.
