# Release History: opentelemetry-instrumentation-action_pack

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259))
* remove enable_recognize_route and span_naming options ([#214](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/214))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Drop Rails 5 Support ([#259](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/259)) ([b0d5aa6](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/b0d5aa68dd660546d28f8f89ef9004ec776c7bf6))
* Drop Rails 6.0 EOL ([#680](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/680)) ([3f44472](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3f44472230964017d1831a47ea0661dc92d55909))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* name ActionPack spans with the HTTP method and route ([#123](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/123)) ([4a65b3d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/4a65b3d7f76603eba1d958964c64093f47846929))
* Use Rack Middleware Helper ([#428](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/428)) ([78a137e](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/78a137e6e95e4f4358e9a0f46d5e3e929e9f35be))


### Bug Fixes

* Add Rails 7.1 compatability ([#684](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/684)) ([93dcf35](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/93dcf359a8a66d17fed545f7a642f1d3a83d4ef4))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* declare span_naming option in action_pack instrumentation ([#157](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/157)) ([274af43](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/274af43974a6830e883032661bddefbd2bdd0570))
* Drop Rails dependency for ActiveSupport Instrumentation ([#242](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/242)) ([c571ece](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c571ecee6283e877fb7df3ea2b01acf722410551))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* remove enable_recognize_route and span_naming options ([#214](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/214)) ([ea604aa](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/ea604aa77e0d4c26e1d178877dea75c795f039ee))
* RubyGems Fallback ([#1161](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1161)) ([3b03ff7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3b03ff7ea66b69c85ba205a369b85c2c33b712fe))
* use rails request's filtered path as http.target attribute ([#1125](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1125)) ([ad51972](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/ad51972e9bdc8ead0e69642056a4935683464dfc))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.8.0 / 2023-11-22

* BREAKING CHANGE: Drop Rails 6.0 EOL

* ADDED: Drop Rails 6.0 EOL

### v0.7.1 / 2023-10-16

* FIXED: Add Rails 7.1 compatibility

### v0.7.0 / 2023-06-05

* ADDED: Use Rack Middleware Helper
* FIXED: Base config options 

### v0.6.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7 

### v0.5.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 
* FIXED: Drop Rails dependency for ActiveSupport Instrumentation 

### v0.4.1 / 2023-01-14

* FIXED: String-ify code.function Span attribute
* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.4.0 / 2022-12-06

* BREAKING CHANGE: Remove enable_recognize_route and span_naming options 

* FIXED: Remove enable_recognize_route and span_naming options 

### v0.3.2 / 2022-11-16

* FIXED: Loosen dependency on Rack

### v0.3.1 / 2022-10-27

* FIXED: Declare span_naming option in action_pack instrumentation

### v0.3.0 / 2022-10-14

* ADDED: Name ActionPack spans with the HTTP method and route 

### v0.2.1 / 2022-10-04

* FIXED: Ensures the correct route is add to http.route span attribute 

### v0.2.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.1.4 / 2022-05-02

* FIXED: Use rails request's filtered path as http.target attribute 
* FIXED: RubyGems Fallback 

### v0.1.3 / 2021-12-01

* FIXED: Instrumentation of Rails 7 

### v0.1.2 / 2021-10-06

* FIXED: Prevent high cardinality rack span name as a default 

### v0.1.1 / 2021-09-29

* (No significant changes)

### v0.1.0 / 2021-08-12

* Initial release.
