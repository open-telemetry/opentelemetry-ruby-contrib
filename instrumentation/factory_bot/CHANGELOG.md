# Release History: opentelemetry-instrumentation-factory_bot

## v0.1.0 / 2025-01-03

* Initial release
* Instruments FactoryBot operations via ActiveSupport::Notifications
* Captures create, build, build_stubbed, and attributes_for strategies
* Includes factory name, strategy, and traits in span attributes
