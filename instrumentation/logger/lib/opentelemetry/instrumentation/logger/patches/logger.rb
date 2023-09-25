# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Instrumention for methods from Ruby's Logger class
        module Logger
          # TODO: Make sure OTel logs aren't instrumented
          # TODO: How to pass attributes?

          def format_message(severity, datetime, progname, msg)
            formatted_message = super(severity, datetime, progname, msg)
            return formatted_message if skip_instrumenting?

            return formatted_message if instance_variable_get(:@skip_instrumenting) == true

            # TODO: Is there another way I can find the logger that's more
            # similar to how the tracers are found/set?
            OpenTelemetry.logger_provider.logger(
              'opentelemetry-instrumentation-logger',
              OpenTelemetry::Instrumentation::Logger::VERSION
            ).emit(
              severity_text: severity,
              severity_number: ::Logger::Severity.const_get(severity),
              timestamp: datetime,
              body: formatted_message
            )
          end

          private

          def instrumentation_config; end

          def skip_instrumenting?
            instance_variable_get(:@skip_instrumenting)
          end
        end
      end
    end
  end
end
