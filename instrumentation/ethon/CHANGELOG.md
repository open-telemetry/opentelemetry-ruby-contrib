# Release History: opentelemetry-instrumentation-ethon

### v0.23.0 / 2025-07-29

* ADDED: Add Ethon `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable [#1561](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/1561)

### v0.22.0 / 2025-01-16

* BREAKING CHANGE: Set minimum supported version to Ruby 3.1

* ADDED: Set minimum supported version to Ruby 3.1

### v0.21.9 / 2024-11-26

* CHANGED: Performance Freeze all range objects #1222

### v0.21.8 / 2024-07-23

* DOCS: Add cspell to CI

### v0.21.7 / 2024-06-18

* FIXED: Relax otel common gem constraints

### v0.21.6 / 2024-06-12

* FIXED: Add net.peer.name to ethon

### v0.21.5 / 2024-05-09

* FIXED: Untrace entire request

### v0.21.4 / 2024-04-30

* FIXED: Bundler conflict warnings

### v0.21.3 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.21.2 / 2023-07-21

* ADDED: Update `opentelemetry-common` from [0.19.3 to 0.20.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/537)

### v0.21.1 / 2023-06-05

* FIXED: Base config options 

### v0.21.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.20.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.20.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.19.5 / 2022-05-05

* (No significant changes)

### v0.19.4 / 2022-02-02

* FIXED: Excessive hash creation on context attr merging 

### v0.19.3 / 2021-12-02

* (No significant changes)

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API dependency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* ADDED: Ethon instrumentation accepts peer service config attribute.
* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* FIXED: Remove passwords from http.url
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* (No significant changes)

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

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module
* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Move context/span methods to Trace module
* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Add README for Ethon
* DOCS: Standardize top-level docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
