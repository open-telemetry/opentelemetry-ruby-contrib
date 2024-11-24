# Release History: opentelemetry-instrumentation-active_job

## [0.7.2](https://github.com/open-telemetry/opentelemetry-ruby-contrib/compare/opentelemetry-instrumentation-active_job/v0.7.1...opentelemetry-instrumentation-active_job/v0.7.2) (2024-11-24)


### Bug Fixes

* **active-job:** honour dynamic changes in configuration ([df6e43f](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/df6e43f9a350afeca3066e2ceba0ed5112d9d47f))
* **active-job:** Honour dynamic changes in configuration ([#1079](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1079)) ([df6e43f](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/df6e43f9a350afeca3066e2ceba0ed5112d9d47f))
* **active-job:** Prefix ::ActiveSupport when installing the instrumentation ([#1120](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1120)) ([c51c0ee](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c51c0eed894429d33a4de3b8a981a84971c19611))
* **active-job:** Propagate context between enqueue and perform ([#1132](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1132)) ([9927df8](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/9927df8012a51a34653c36f373a2e8d9b19ed7cf))
* ActiveJob Propagate baggage information properly when performing ([#1214](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1214)) ([5b1c09d](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/5b1c09d2dbbd34cec698eb738fa01503e21db2cd))
* ActiveJob::Handlers.unsubscribe ([#1078](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1078)) ([8b9aba3](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/8b9aba33e51f95255c9440f74664ca29ef08aed6))
* Use Active Support Lazy Load Hooks to avoid prematurely initializing ActiveRecord::Base and ActiveJob::Base ([#1104](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1104)) ([a9e6e1a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a9e6e1a898f89ac6574a85f3f64429fbf4b457db))


### Performance Improvements

* Reduce Context Allocations in ActiveJob ([#1018](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1018)) ([989da17](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/989da17c33c345ad285f70a0821078a6e21d389d))

### v0.7.8 / 2024-10-24

* FIXED: ActiveJob Propagate baggage information properly when performing

### v0.7.7 / 2024-08-21

* FIXED: Propagate context between enqueue and perform

### v0.7.6 / 2024-08-15

* FIXED: Prefix ::ActiveSupport when installing the instrumentation

### v0.7.5 / 2024-08-15

* FIXED: Use Active Support Lazy Load Hooks to avoid prematurely initializing ActiveRecord::Base and ActiveJob::Base

### v0.7.4 / 2024-07-30

* FIXED: Honour dynamic changes in configuration

### v0.7.3 / 2024-07-22

* FIXED: ActiveJob::Handlers.unsubscribe

### v0.7.2 / 2024-07-02

* DOCS: Fix CHANGELOGs to reflect a past breaking change

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

* BREAKING CHANGE: Align messaging instrumentation operation names [#648](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/648)

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
