# Release History: opentelemetry-instrumentation-action_pack

### v0.4.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.4.0 / 2022-12-06

* BREAKING CHANGE: Remove enable_recognize_route and span_naming options 

* FIXED: Remove enable_recognize_route and span_naming options 

### v0.3.2 / 2022-11-16

* * FIXED: Loosen dependency on Rack

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
