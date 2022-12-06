# Release History: opentelemetry-instrumentation-pg

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
