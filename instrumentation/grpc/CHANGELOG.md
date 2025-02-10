# Release History: opentelemetry-instrumentation-grpc

### v0.2.0 / 2025-02-11

* First release of the gem after the donation

* BREAKING CHANGE: Set minimum supported version to Ruby 3.1

* BREAKING CHANGE: Manual stub instrumentation via interceptor setup is now obsolete. After OpenTelemetry is installed, every new stub instance is automatically instrumented. This aligns the instrumentation behavior with other libraries, eliminating the need for users to manually add interceptors.

* FIXED: Refactored instrumentation from patch-style to use interceptors.

### v0.1.3 / 2024-09-11

* FIXED: Fix error in handling of non-gRPC errors
* FIXED: Fix error in method signature for OpenTelemetry::Instrumentation::Grpc.client_interceptor [#1](https://github.com/hibachrach/opentelemetry-instrumentation-grpc/pull/1)

### v0.1.2 / 2024-06-26

* FIXED: Align span naming with spec

### v0.1.1 / 2024-06-26

* FIXED: Fix `uninitialized constant Interceptors` error

### v0.1.0 / 2024-06-18

* Initial release
