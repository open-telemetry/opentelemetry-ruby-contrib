# Release History: opentelemetry-instrumentation-trilogy

### v0.59.3 / 2024-04-30

* FIXED: Bundler conflict warnings

### v0.59.2 / 2024-02-20

* FIXED: Dup string if frozen in trilogy query

### v0.59.1 / 2024-02-08

* FIXED: Add missing requires for sql-helpers to mysql, pg, and trilogy instrumentation

### v0.59.0 / 2024-02-08

* BREAKING CHANGE: Move shared sql behavior to helper gems

* ADDED: Propagate context to Vitess

### v0.58.0 / 2024-01-06

* BREAKING CHANGE: Change db.mysql.instance.address to db.instance.id

* ADDED: Change db.mysql.instance.address to db.instance.id
* FIXED: Trilogy only set db.instance.id attribute if there is a value

### v0.57.0 / 2023-10-27

* ADDED: Instrument connect and ping

### v0.56.3 / 2023-08-03

* FIXED: Remove inline linter rules

### v0.56.2 / 2023-07-14

* ADDED: `db.user` attribute (recommended connection-level attribute)

### v0.56.1 / 2023-06-05

* FIXED: Base config options 

### v0.56.0 / 2023-06-02

* BREAKING CHANGE: Separate logical MySQL host from connected host 

* ADDED: Separate logical MySQL host from connected host 

### v0.55.1 / 2023-06-01

* FIXED: Regex non-match with obfuscation limit (issue #486) 

### v0.55.0 / 2023-05-31

* BREAKING CHANGE: Add database name for trilogy traces 

* ADDED: Add database name for trilogy traces 

### v0.54.0 / 2023-05-25

* ADDED: Add Obfuscation Limit Option to Trilogy 

### v0.53.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.52.0 / 2023-03-06

* ADDED: Add with_attributes context propagation to Trilogy instrumentation 
* ADDED: Add option to configure span name for trilogy 
* FIXED: Ensure encoding errors handled during SQL obfuscation for Trilogy 

### v0.51.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.51.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.50.2 / 2022-05-05

* (No significant changes)

### v0.50.1 / 2022-01-07

* FIXED: Trilogy Driver Options 

### v0.50.0 / 2021-12-31

* Initial release.
