# Release History: opentelemetry-instrumentation-active_record

### v0.6.2 / 2023-08-14

* FIXED: Ensure that transaction name property is used, rather than self

### v0.6.1 / 2023-06-05

* FIXED: Base config options 

### v0.6.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.5.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 

### v0.4.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.4.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.3.0 / 2022-05-02

* ADDED: Make ActiveRecord 7 compatible 
* FIXED: RubyGems Fallback 

### v0.2.2 / 2021-12-01

* FIXED: Add max supported version for active record 

### v0.2.1 / 2021-09-29

* (No significant changes)

### v0.2.0 / 2021-09-29

* ADDED: Trace update_all and delete_all calls in ActiveRecord 
* FIXED: Remove Active Record instantiation patch 

### v0.1.1 / 2021-08-12

* (No significant changes)

### v0.1.0 / 2021-07-08

* Initial release, adds instrumentation patches to querying and persistence methods.
