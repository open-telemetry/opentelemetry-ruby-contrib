# Release History: opentelemetry-propagator-ottrace

### v0.24.0 / 2025-10-22

* BREAKING CHANGE: Min Ruby Version 3.2

* ADDED: Min Ruby Version 3.2

### v0.23.0 / 2025-09-30

* ADDED: Bump minimum API Version to 1.7

### v0.22.0 / 2025-01-16

* BREAKING CHANGE: Set minimum supported version to Ruby 3.1

* ADDED: Set minimum supported version to Ruby 3.1

### v0.21.4 / 2024-11-26

* (No significant changes)

### v0.21.3 / 2024-07-23

* DOCS: Add cspell to CI

### v0.21.2 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.21.1 / 2023-07-19

* DOCS: Add some clarity to ottrace docs [#522](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/522)

### v0.21.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7

* ADDED: Drop support for EoL Ruby 2.7 
* DOCS: Update URLs to rubydocs 

### v0.20.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.20.0 / 2022-06-09

* (No significant changes)

### v0.19.3 / 2021-10-29

* FIXED: Add Support fo OTTrace Bit Encoded Sampled Flags 

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-08-12

* (No significant changes)

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Refactor Baggage to remove Noop* 

* ADDED: Add Tracer.non_recording_span to API 
* FIXED: Support Case Insensitive Trace and Span IDs 
* FIXED: Refactor Baggage to remove Noop* 

### v0.18.0 / 2021-05-21

* ADDED: Updated API dependency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* BREAKING CHANGE: Replace TextMapInjector/TextMapExtractor pairs with a TextMapPropagator.

  [Check the propagator documentation](https://www.rubydoc.info/gems/opentelemetry-propagator-ottrace) for the new usage.

* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* Initial release.
