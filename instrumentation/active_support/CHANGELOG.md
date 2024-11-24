# Release History: opentelemetry-instrumentation-active_support

## [0.6.0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/compare/opentelemetry-instrumentation-active_support/v0.5.1...opentelemetry-instrumentation-active_support/v0.6.0) (2024-11-24)


### ⚠ BREAKING CHANGES

* Custom ActiveSupport Span Names ([#1014](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1014))

### Features

* ActiveSupport user specified span kind ([#1016](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1016)) ([a9c45e7](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a9c45e7c36ffd769bb89207572ca5ebd3aa9852d))
* Custom ActiveSupport Span Names ([#1014](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1014)) ([e14d6b0](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/e14d6b0e69a27fd22d9bacabef3a99c32ce1fde9))


### Bug Fixes

* Include span kind in ActiveSupport Instrumentation helper ([#1036](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/1036)) ([a324938](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/a3249381392bbfdb7ce06a69bcc6840a0d955c7b))

### v0.6.0 / 2024-07-02

* BREAKING CHANGE: Custom ActiveSupport Span Names

* ADDED: Custom ActiveSupport Span Names

### v0.5.3 / 2024-06-20

* FIXED: Include span kind in ActiveSupport Instrumentation helper

### v0.5.2 / 2024-06-20

* ADDED: ActiveSupport user specified span kind

### v0.5.1 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.5.0 / 2023-11-22

* BREAKING CHANGE: Drop Rails 6.0 EOL

* ADDED: Drop Rails 6.0 EOL

### v0.4.4 / 2023-10-31

* FIXED: Remove call to ActiveSupport::Notifications.notifier#synchronize deprecated in Rails 7.2

### v0.4.3 / 2023-10-16

* FIXED: Add Rails 7.1 compatibility

### v0.4.2 / 2023-09-07

FIXED: Reduce Object allocation

### v0.4.1 / 2023-06-05

* FIXED: Base config options 

### v0.4.0 / 2023-04-17

* BREAKING CHANGE: Drop support for EoL Ruby 2.7 

* ADDED: Drop support for EoL Ruby 2.7 

### v0.3.0 / 2023-02-01

* BREAKING CHANGE: Drop Rails 5 Support 

* ADDED: Drop Rails 5 Support 

### v0.2.2 / 2023-01-14

* FIXED: Drop Rails dependency for ActiveSupport Instrumentation 

### v0.2.1 / 2023-01-14

* DOCS: Fix gem homepage 
* DOCS: More gem documentation fixes 

### v0.2.0 / 2022-06-09

* Upgrading Base dependency version
* FIXED: Broken test file requirements 

### v0.1.2 / 2022-05-05

* (No significant changes)

### v0.1.1 / 2021-12-02

* (No significant changes)

### v0.1.0 / 2021-11-09

* Initial release.
