# Release History: opentelemetry-instrumentation-mysql2

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* obfuscation for mysql2, dalli and postgresql as default option for db_statement ([#682](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/682))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Removed deprecated instrumentation options ([#265](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/265))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* add `with_attributes` context propagation for mysql2 instrumentation ([#1175](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1175)) ([aa4ce24](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/aa4ce24dc88c1a5cad7e71872076ce89d9547c28))
* add config[:obfuscation_limit] to pg and mysql2 ([#224](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/224)) ([b369020](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b36902099ea90dc23d06bdc424a3fd6d08d5f9d7))
* Add Obfuscation Limit Option to Trilogy ([#477](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/477)) ([234738c](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/234738c5fbd8d630d543f61d84fcefcf948756f1))
* add option to configure span name ([#222](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/222)) ([99026b1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/99026b14cfe23d702b8ec99bf05d48593b15ec71))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* obfuscation for mysql2, dalli and postgresql as default option for db_statement ([#682](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/682)) ([20e1cd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/20e1cd04f8167276453b27469912e90984a291ac))
* Removed deprecated instrumentation options ([#265](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/265)) ([bf82e8d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bf82e8d5e25766de99b803e23af6c5666c5bfc5b))


### Bug Fixes

* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* Ensure encoding errors handled during SQL obfuscation for Trilogy ([#345](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/345)) ([1a5972f](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/1a5972f449e920bd3b54fc1033121d72f906c771))
* handle encoding errors in mysql obfuscation ([#160](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/160)) ([ed4eec3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/ed4eec3320cc35079191416ef0cb6268fe51be60))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([b31a4cb](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b31a4cbb20ba7ee4a3422ce65f948a7fa3f43f85))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.25.0 / 2023-10-16

* BREAKING CHANGE: Obfuscation for mysql2, dalli and postgresql as default option for db_statement

* ADDED: Obfuscation for mysql2, dalli and postgresql as default option for db_statement

### v0.24.3 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.24.2 / 2023-06-05

* FIXED: Base config options 

### v0.24.1 / 2023-06-01

* FIXED: Regex non-match with obfuscation limit (issue #486)

### v0.24.0 / 2023-05-25

* ADDED: Add config[:obfuscation_limit] to pg and mysql2

### v0.23.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7
* FIXED: Ensure encoding errors handled during SQL obfuscation for Trilogy

### v0.22.0 / 2023-01-14

* BREAKING CHANGE: Removed deprecated instrumentation options

* ADDED: Add option to configure span name
* ADDED: Removed deprecated instrumentation options
* DOCS: Fix gem homepage
* DOCS: More gem documentation fixes

### v0.21.1 / 2022-10-26

* FIXED: Handle encoding errors in mysql obfuscation

### v0.21.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements

### v0.20.1 / 2022-05-03

* ADDED: `with_attributes` method for context propagation

### v0.20.0 / 2021-12-01

* ADDED: Add default options config helper + env var config option support

### v0.19.1 / 2021-09-29

* (No significant changes)

### v0.19.0 / 2021-08-12

* BREAKING CHANGE: Add option for db.statement

* ADDED: Add option for db.statement
* DOCS: Update docs to rely more on environment variable configuration
* DOCS: Move to using new db_statement

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* Fix: Nil value for db.name attribute #744

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* FIXED: Update DB semantic conventions
* FIXED: Example scripts now reference local common lib
* ADDED: Configurable obfuscation of sql in mysql2 instrumentation to avoid logging sensitive data

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* ADDED: Add peer service config to mysql
* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Semantic conventions db.type -> db.system

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
