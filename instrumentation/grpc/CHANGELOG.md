# Release History: opentelemetry-instrumentation-grpc

### v0.2.1 / 2025-04-17

* CHANGED: Fix ClientTracer: uninitialized constant GRPC (NameError) https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/1471

### v0.2.0 / 2025-04-02

* ADDED: Add gRPC trace demonstration
* ADDED: Migrate gRPC instrumentation to OpenTelemetry tooling
* ADDED: Transferred ownership of the gem from @hibachrach to OpenTelemetry

### v0.1.3 / 2024-09-11

* FIXED: Fix error in handling of non-gRPC errors
* FIXED: Fix error in method signature for OpenTelemetry::Instrumentation::Grpc.client_interceptor [#1](https://github.com/hibachrach/opentelemetry-instrumentation-grpc/pull/1)

### v0.1.2 / 2024-06-26

* FIXED: Align span naming with spec

### v0.1.1 / 2024-06-26

* FIXED: Fix `uninitialized constant Interceptors` error

### v0.1.0 / 2024-06-18

* Initial release
