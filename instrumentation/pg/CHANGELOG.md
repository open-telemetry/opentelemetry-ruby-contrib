# Release History: opentelemetry-instrumentation-pg

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* obfuscation for mysql2, dalli and postgresql as default option for db_statement ([#682](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/682))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Removed deprecated instrumentation options ([#265](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/265))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Add `with_attributes` context propagation for PG instrumentation ([#101](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/101)) ([a11d8b1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a11d8b135d9ac4c28521619dc3b4744692ae2e6e))
* add config[:obfuscation_limit] to pg and mysql2 ([#224](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/224)) ([b369020](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b36902099ea90dc23d06bdc424a3fd6d08d5f9d7))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* obfuscation for mysql2, dalli and postgresql as default option for db_statement ([#682](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/682)) ([20e1cd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/20e1cd04f8167276453b27469912e90984a291ac))
* Removed deprecated instrumentation options ([#265](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/265)) ([bf82e8d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bf82e8d5e25766de99b803e23af6c5666c5bfc5b))
* Validate Using Enums ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([7cd4b10](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7cd4b10ba516cecbb15a40dbe3bd5ed3860b1f88))


### Bug Fixes

* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* only take the first item in a comma-separated list for pg attrs ([#142](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/142)) ([82093a9](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/82093a9edf478688d70432c036554dd2f979d7c6))
* Pass block explicitly in `define_method` calls for PG instrumentation query methods ([#574](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/574)) ([84f7b64](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/84f7b641a38f059bc00ffc6678d0bdc283cffbbb))
* **pg:** safeguard against host being nil ([#178](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/178)) ([38e975b](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/38e975bed8c3e2e0742007d1690bb81135341311))
* Reduce Hash Allocations in PG Instrumentation ([#232](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/232)) ([53a5b26](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/53a5b26b471e692d7e85625c0f964510e4deef50))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([b31a4cb](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b31a4cbb20ba7ee4a3422ce65f948a7fa3f43f85))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))
* update pg instrumentation to handle non primitive argument ([#1146](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1146)) ([8eac4a1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/8eac4a112f996e088e693add37227c11a67baa2d))
* Use attributes from the active PG connection ([#185](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/185)) ([207369a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/207369a5970548d32a4d3c19c9a85452509a1ddc))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.26.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.26.0 / 2023-10-16

* BREAKING CHANGE: Obfuscation for mysql2, dalli and postgresql as default option for db_statement

* ADDED: Obfuscation for mysql2, dalli and postgresql as default option for db_statement

### v0.25.3 / 2023-07-29

* FIXED: Pass block explicitly in `define_method` calls for PG instrumentation query methods

### v0.25.2 / 2023-06-05

* FIXED: Base config options 

### v0.25.1 / 2023-06-01

* FIXED: Regex non-match with obfuscation limit (issue #486) 

### v0.25.0 / 2023-05-25

* ADDED: Add config[:obfuscation_limit] to pg and mysql2 

### v0.24.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.23.0 / 2023-01-14

* BREAKING CHANGE: Removed deprecated instrumentation options 

* ADDED: Removed deprecated instrumentation options 
* FIXED: Reduce Hash Allocations in PG Instrumentation 
* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.22.3 / 2022-12-06

* FIXED: Use attributes from the active PG connection

### v0.22.2 / 2022-11-10

* FIXED: Safeguard against host being nil

### v0.22.1 / 2022-10-27

* FIXED: Only take the first item in a comma-separated list for pg attrs

### v0.22.0 / 2022-10-04

* ADDED: Add `with_attributes` context propagation for PG instrumentation 

### v0.21.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.20.0 / 2022-05-02

* ADDED: Validate Using Enums 
* FIXED: Update pg instrumentation to handle non primitive argument 
* FIXED: RubyGems Fallback 

### v0.19.2 / 2021-12-02

* (No significant changes)

### v0.19.1 / 2021-09-29

* (No significant changes)

### v0.19.0 / 2021-08-12

* ADDED: Add db_statement toggle for postgres 
* DOCS: Update docs to rely more on environment variable configuration 

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* ADDED: Add option to postgres instrumentation to disable db.statement

### v0.17.1 / 2021-04-23

* Initial release.
* ADDED: Initial postgresql instrumentation
