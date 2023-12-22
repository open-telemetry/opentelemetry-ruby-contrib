# Release History: opentelemetry-instrumentation-active_job

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
* Make the context available in ActiveJob notifications ([#1145](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1145)) ([36bda3d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/36bda3dbc516ccfac2842a942d3fe217be3ac986))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* **active_job:** Fix deserialization of jobs that are missing metadata ([#1143](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1143)) ([37f3922](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/37f39224d48bcee5d085ad88da1be5cb22b63c68))
* Add code semconv attributes ([#591](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/591)) ([54b9496](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/54b9496fb58057d426ae2a5588bb227bf8d6de57))
* Add Rails 7.1 compatability ([#684](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/684)) ([93dcf35](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/93dcf359a8a66d17fed545f7a642f1d3a83d4ef4))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.7.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.7.0 / 2023-11-22

* BREAKING CHANGE: Drop Rails 6.0 EOL

* ADDED: Drop Rails 6.0 EOL

* BREAKING CHANGE: Use ActiveSupport Instrumentation instead of Monkey Patches

* CHANGED: Use ActiveSupport Instrumentation instead of Money Patches [#677](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/677)

### v0.6.1 / 2023-10-16

* FIXED: Add Rails 7.1 compatibility

### v0.6.0 / 2023-09-07

* FIXED: Align messaging instrumentation operation names

### v0.5.2 / 2023-08-03

* FIXED: Add code semconv attributes
* FIXED: Remove inline linter rules

### v0.5.1 / 2023-06-05

* FIXED: Base config options

### v0.5.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.4.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 

### v0.3.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.3.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.2.0 / 2022-05-02

* ADDED: Validate Using Enums 
* ADDED: Make the context available in ActiveJob notifications 
* FIXED: Fix deserialization of jobs that are missing metadata 
* FIXED: RubyGems Fallback 

### v0.1.5 / 2021-12-02

* (No significant changes)

### v0.1.4 / 2021-09-29

* (No significant changes)

### v0.1.3 / 2021-08-12

* (No significant changes)

### v0.1.2 / 2021-07-01

* FIXED: Support Active Jobs with keyword args across ruby versions  

### v0.1.1 / 2021-06-29

* FIXED: Compatibility with RC2 span status api changes [845](https://github.com/open-telemetry/opentelemetry-ruby/pull/845)

### v0.1.0 / 2021-06-23

* Initial release.
