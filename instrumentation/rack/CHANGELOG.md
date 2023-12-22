# Release History: opentelemetry-instrumentation-rack

## 1.0.0 (2023-12-22)


### ⚠ BREAKING CHANGES

* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389))
* Remove retain_middleware_names Rack Option ([#356](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/356))
* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3))

### Features

* Add experimental traceresponse propagator to Rack instrumentation ([#182](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/182)) ([4e2d98b](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/4e2d98bd635e099518fc05041057e94e967186d5))
* Drop support for EoL Ruby 2.7 ([#389](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/389)) ([233dfd0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/233dfd0dae81346e9687090f9d8dfb85215e0ba7))
* Remove retain_middleware_names Rack Option ([#356](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/356)) ([d84a8cb](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/d84a8cb949c5f846174c8136a2b98e06bf265b75))
* Use Rack::Events for instrumentation ([#342](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/342)) ([c179d3b](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c179d3b0f8c69c03867b84c667f98abb66f46a41))


### Bug Fixes

* Backport Rack proxy event to middleware ([#764](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/764)) ([3d0f818](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3d0f818c06a2b246425c114b41bec260b9274bc0))
* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* bring http.request.header and http.response.header in line with … ([#111](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/111)) ([1af9fc1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/1af9fc1a35264dcaf3bd0d88234e8ad8dacdaa22))
* bring http.request.header and http.response.header in line with semantic conventions. ([1af9fc1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/1af9fc1a35264dcaf3bd0d88234e8ad8dacdaa22))
* broken test file requirements ([#1286](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1286)) ([3ec7d8a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3ec7d8a456dbd3c9bbad7b397a3da8b8a311d8e3))
* Ensure Rack Events Handler Exists ([#519](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/519)) ([823883b](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/823883bab58d90c4b92937b25c5acf582bf81fa3))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove inline linter rules ([#608](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/608)) ([bc4a937](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/bc4a937ed2a0d1898f0f19ae45a2b3a0ef9a067c))


### Code Refactoring

* Remove parent repo libraries ([#3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/3)) ([3e85d44](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/3e85d4436d338f326816c639cd2087751c63feb1))

### v0.23.5 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.23.4 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.23.3 / 2023-07-21

* ADDED: Update `opentelemetry-common` from [0.19.3 to 0.20.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/537)

### v0.23.2 / 2023-06-08

* FIXED: Ensure Rack Events Handler Exists

### v0.23.1 / 2023-06-05

* FIXED: Base config options 

### v0.23.0 / 2023-04-17

* BREAKING CHANGE: Remove retain_middleware_names Rack Option 
* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Remove retain_middleware_names Rack Option 
* ADDED: Drop support for EoL Ruby 2.7 
* ADDED: Use Rack::Events for instrumentation 

### v0.22.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.22.0 / 2022-11-16

* ADDED: Add experimental traceresponse propagator to Rack instrumentation

### v0.21.1 / 2022-10-04

* FIXED: Bring http.request.header and http.response.header in line with semconv

### v0.21.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.20.2 / 2022-05-02

* FIXED: Update server instrumentation to not reflect 400 status as error 

### v0.20.1 / 2021-12-01

* FIXED: [Instruentation Rack] Log content type http header 
* FIXED: Use monotonic clock where possible 
* FIXED: Rack to stop using api env getter 

### v0.20.0 / 2021-10-06

* FIXED: Prevent high cardinality rack span name as a default [#973](https://github.com/open-telemetry/opentelemetry-ruby/pull/973)

The default was to set the span name as the path of the request, we have
corrected this as it was not adhering to the spec requirement using low
cardinality span names.  You can restore the previous behaviour of high
cardinality span names by passing in a url quantization function that
forwards the uri path.  More details on this is available in the readme.

### v0.19.3 / 2021-09-29

* (No significant changes)

### v0.19.2 / 2021-08-18

* FIXED: Rack middleware assuming script_name presence 

### v0.19.1 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* ADDED: Add Tracer.non_recording_span to API 
* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* FIXED: Removed http.status_text attribute #750

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* BREAKING CHANGE: Pass env to url quantization rack config to allow more flexibility

* ADDED: Pass env to url quantization rack config to allow more flexibility
* ADDED: Add rack instrumentation config option to accept callable to filter requests to trace
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators
* ADDED: Add untraced endpoints config to rack middleware

### v0.13.0 / 2021-01-29

* FIXED: Only include user agent when present

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Rack current_span

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Instrument rails
* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module
* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Move context/span methods to Trace module
* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* FIXED: Remove superfluous file from Rack gem
* DOCS: Added README for Rack Instrumentation
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
