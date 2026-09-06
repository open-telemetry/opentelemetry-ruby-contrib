# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      # Base Plugin
      module Plugin
        # loads httpx tracing plugin
        def self.load_dependencies(klass)
          klass.plugin(:tracing)
        end

        # Request patch to initiate the trace on initialization.
        module RequestMethods
          attr_accessor :otel_span
        end

        # base request tracer
        module RequestTracer
          # whether tracing is enabled
          def enabled?(request)
            true
          end

          # on request started callback
          def start(request)
            request.otel_span = initialize_span(request)
          end

          # on request reset callback
          def reset(request)
            request.otel_span = nil
          end

          # on request finished callback
          def finish(request, response)
            request.otel_span ||= initialize_span(request, request.init_time) if request.init_time

            finish_span(response, request.otel_span)
          end
        end
      end
    end
  end
end
