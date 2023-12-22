# Release History: opentelemetry-instrumentation-active_support

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259)) ([b0d5aa6](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b0d5aa68dd660546d28f8f89ef9004ec776c7bf6))
* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680)) ([3f44472](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3f44472230964017d1831a47ea0661dc92d55909))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))


### Bug Fixes

* Add Rails 7.1 compatability ([#684](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/684)) ([93dcf35](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/93dcf359a8a66d17fed545f7a642f1d3a83d4ef4))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* Drop Rails dependency for ActiveSupport Instrumentation ([#242](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/242)) ([c571ece](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c571ecee6283e877fb7df3ea2b01acf722410551))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* remove call to ActiveSupport::Notifications.notifier#synchronize deprecated in Rails 7.2 ([#707](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/707)) ([828e137](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/828e1379fa626078fc9ca278d863481e4c01dc70))


### Performance Improvements

* Reduce Object allocation ([#642](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/642)) ([a906f74](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a906f7465c44edc70ab45a354120905cfcceeb50))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.5.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.5.0 / 2023-11-22

* BREAKING CHANGE: Drop Rails 6.0 EOL

* ADDED: Drop Rails 6.0 EOL

### v0.4.4 / 2023-10-31

* FIXED: Remove call to ActiveSupport::Notifications.notifier#synchronize deprecated in Rails 7.2

### v0.4.3 / 2023-10-16

* FIXED: Add Rails 7.1 compatibility

### v0.4.2 / 2023-09-07

FIXED: Reduce Object allocation

### v0.4.1 / 2023-06-05

* FIXED: Base config options 

### v0.4.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.3.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 

### v0.2.2 / 2023-01-14

* FIXED: Drop Rails dependency for ActiveSupport Instrumentation 

### v0.2.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.2.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.1.2 / 2022-05-05

* (No significant changes)

### v0.1.1 / 2021-12-02

* (No significant changes)

### v0.1.0 / 2021-11-09

* Initial release.
