# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      QUERY_SPAN_NAME_KEY = OpenTelemetry::Context.create_key('async_query_span_name')

      module Patches
        # Module to prepend to ActiveRecord::ConnectionAdapters::ConnectionPool.
        # This is only installed if OpenTelemetry::Instrumentation::ConcurrentRuby is not defined.
        module AsyncQueryContextPropagation
          def schedule_query(future_result) # :nodoc:
            context = OpenTelemetry::Context.current

            @async_executor.post do
              # This can happen in the request thread, in the case of a busy executor (fallback_action is executed.)
              OpenTelemetry::Context.with_current(context) do
                future_result.execute_or_skip
              end
            end

            Thread.pass
          end
        end

        # Module to support otel context propagation to ActiveRecord::FutureResults
        module FutureResultExtensions
          OTEL_QUERY_SPAN_NAME_IVAR = :@__otel_query_span_name

          def initialize(...)
            super

            if (query_span_name = OpenTelemetry::Context.current.value(QUERY_SPAN_NAME_KEY))
              instance_variable_set(OTEL_QUERY_SPAN_NAME_IVAR, query_span_name)
            end
          end

          private

          def execute_query(connection, async: false)
            name = instance_variable_get(OTEL_QUERY_SPAN_NAME_IVAR) || @args[1] || 'execute_query'
            Instrumentation.instance.tracer.in_span(name, attributes: { 'async' => async }) do
              super
            end
          end
        end
      end
    end
  end
end
